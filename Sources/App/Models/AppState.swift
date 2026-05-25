import AppKit
import Combine
import Foundation

enum MissingPermission {
    case none, inputMonitoring, microphone
}

final class AppState: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isTransformRecording = false
    @Published private(set) var hasMicrophonePermission = false
    @Published private(set) var transcriptionState: TranscriptionState = .idle

    var missingPermission: MissingPermission {
        if !hotkeyService.isAvailable { return .inputMonitoring }
        if !audioService.isMicrophoneAuthorized { return .microphone }
        return .none
    }

    var isAccessibilityAuthorized: Bool { pasteService.isAccessibilityAuthorized }

    @Published var dictationStyle: DictationStyle = {
        let raw = UserDefaults.standard.string(forKey: StorageKey.Defaults.dictationStyle) ?? ""
        return DictationStyle(rawValue: raw) ?? .neutral
    }() {
        didSet { UserDefaults.standard.set(dictationStyle.rawValue, forKey: StorageKey.Defaults.dictationStyle) }
    }

    /// Aktiver eigener Stil – überschreibt `dictationStyle` wenn gesetzt.
    @Published private(set) var selectedCustomStyle: CustomStyle?

    func selectFixedStyle(_ style: DictationStyle) {
        dictationStyle = style
        selectedCustomStyle = nil
    }

    func selectCustomStyle(_ style: CustomStyle) {
        selectedCustomStyle = style
    }

    let hotkeyService: HotkeyService
    let audioService: AudioService
    let whisperService: WhisperService
    let pasteService: PasteService
    let appleSpeechService = AppleSpeechService()
    let settings = AppSettings()
    let dictionaryService = DictionaryService()
    let historyService = HistoryService()
    let statsService = StatsService()

    var onOpenSettings: (() -> Void)?
    var onOpenHelp: (() -> Void)?

    private var targetApp: NSRunningApplication?
    @Published private(set) var isTransformMode = false
    @Published private(set) var isTransformResult = false
    private var selectedTextForTransform: String?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let audio   = AudioService()
        let hotkey  = HotkeyService(dictation: settings.dictationShortcut,
                                    transform: settings.transformShortcut)
        let whisper = WhisperService()
        let paste   = PasteService()
        audioService   = audio
        hotkeyService  = hotkey
        whisperService = whisper
        pasteService   = paste
        hasMicrophonePermission = audio.isMicrophoneAuthorized

        setupWhisperBinding()
        audio.requestPermissionIfNeeded { [weak self] granted in
            DispatchQueue.main.async { self?.hasMicrophonePermission = granted }
        }
        setupAppleSpeechCallbacks()
        setupHotkeyCallbacks()
        setupSettingsBindings()

        Task { await whisperService.loadModelIfNeeded(model: settings.whisperModel) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            paste.requestAccessibilityIfNeeded()
        }
        appleSpeechService.requestAuthorization { _ in }
    }

    // MARK: – Berechtigungen

    func recheckPermissions() {
        hotkeyService.retryIfNeeded()
        hasMicrophonePermission = audioService.isMicrophoneAuthorized
        pasteService.requestAccessibilityIfNeeded()
        objectWillChange.send()
    }

    // MARK: – Stil-Aktionen

    // MARK: – Ergebnis / Fehler

    @MainActor
    func dismissResult() {
        isTransformResult = false
        transcriptionState = .idle
    }

    @MainActor
    func dismissError() {
        transcriptionState = .idle
    }

    // MARK: – Text-Einfügung (Preview-Bestätigung)

    @MainActor
    func confirmPaste(original: String, edited: String) async {
        dictionaryService.learnFromDiff(original: original, edited: edited)

        let app = targetApp
        targetApp = nil

        if let app, app.bundleIdentifier != Bundle.main.bundleIdentifier {
            app.activate(options: .activateIgnoringOtherApps)
            try? await Task.sleep(nanoseconds: 100_000_000)
            pasteService.paste(text: edited)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        historyService.add(text: edited)
        isTransformResult = false
        transcriptionState = .idle
    }
}

// MARK: – Init-Hilfsmethoden (Wiring)

private extension AppState {

    func setupWhisperBinding() {
        whisperService.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                if case .done(let text) = state {
                    Task { @MainActor [weak self] in
                        await self?.handleTranscriptionDone(text: text)
                    }
                } else {
                    self.transcriptionState = state
                }
            }
            .store(in: &cancellables)
    }

    func setupAppleSpeechCallbacks() {
        appleSpeechService.onPartialResult = { [weak self] text in
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }
                if self.settings.llmProvider == .disabled {
                    self.transcriptionState = .streaming(text)
                }
            }
        }
        appleSpeechService.onFinalResult = { [weak self] text in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isRecording = false
                self.isTransformRecording = false
                await self.handleTranscriptionDone(text: text)
            }
        }
        appleSpeechService.onError = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isRecording = false
                self.isTransformRecording = false
                self.transcriptionState = .error(.appleSpeechUnavailable)
            }
        }
    }

    func setupHotkeyCallbacks() {
        hotkeyService.onKeyDown = { [weak self] in
            guard let self else { return }
            targetApp = NSWorkspace.shared.frontmostApplication
            isRecording = true
            if settings.soundFeedbackEnabled { SoundFeedback.playStart() }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.startRecording(locale: settings.whisperLanguage.appleLocale)
            } else {
                audioService.startRecording()
            }
        }
        hotkeyService.onKeyUp = { [weak self] in
            guard let self else { return }
            if settings.soundFeedbackEnabled { SoundFeedback.playStop() }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.stopRecording()
                // isRecording wird in onFinalResult zurückgesetzt
            } else {
                isRecording = false
                let model    = settings.whisperModel
                let language = settings.whisperLanguage
                if let url = audioService.stopRecording() {
                    Task { await self.whisperService.transcribe(fileURL: url, model: model, language: language) }
                }
            }
        }
        hotkeyService.onTransformKeyDown = { [weak self] in
            guard let self else { return }
            targetApp = NSWorkspace.shared.frontmostApplication
            isTransformMode     = true
            isRecording         = true
            isTransformRecording = true
            if settings.soundFeedbackEnabled { SoundFeedback.playStart() }
            Task { @MainActor [weak self] in
                self?.selectedTextForTransform = await self?.pasteService.captureSelectedText()
            }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.startRecording(locale: settings.whisperLanguage.appleLocale)
            } else {
                audioService.startRecording()
            }
        }
        hotkeyService.onTransformKeyUp = { [weak self] in
            guard let self else { return }
            if settings.soundFeedbackEnabled { SoundFeedback.playStop() }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.stopRecording()
                // isRecording/isTransformRecording werden in onFinalResult zurückgesetzt
            } else {
                isRecording          = false
                isTransformRecording = false
                let model    = settings.whisperModel
                let language = settings.whisperLanguage
                if let url = audioService.stopRecording() {
                    Task { await self.whisperService.transcribe(fileURL: url, model: model, language: language) }
                }
            }
        }
    }

    func setupSettingsBindings() {
        // Settings-Änderungen an AppState.objectWillChange weiterleiten,
        // damit alle Views (z.B. PopoverRootView) neu rendern wenn sich
        // customStyles, llmProvider etc. ändern.
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Shortcut-Änderungen aus Settings → HotkeyService weiterleiten
        settings.$dictationShortcut
            .dropFirst()
            .sink { [weak self] config in self?.hotkeyService.dictationShortcut = config }
            .store(in: &cancellables)
        settings.$transformShortcut
            .dropFirst()
            .sink { [weak self] config in self?.hotkeyService.transformShortcut = config }
            .store(in: &cancellables)
    }
}

// MARK: – Transkriptions-Pipeline

private extension AppState {

    @MainActor
    func handleTranscriptionDone(text: String) async {
        if isTransformMode {
            isTransformMode = false
            await handleTransformDone(command: text)
            return
        }

        let effectivePrompt: String
        if let custom = selectedCustomStyle {
            effectivePrompt = custom.prompt
        } else {
            effectivePrompt = dictationStyle.systemPrompt ?? settings.ollamaPrompt
        }

        let raw: String
        if settings.llmProvider != .disabled {
            let stream: AsyncThrowingStream<String, Error>
            do {
                stream = try LLMProcessorFactory.dictationStream(
                    settings: settings,
                    systemPrompt: effectivePrompt,
                    text: text
                )
            } catch let e as DictoError {
                transcriptionState = .error(e)
                return
            } catch {
                transcriptionState = .error(.ollamaNotReachable)
                return
            }
            guard let accumulated = await runLLMStream(stream) else { return }
            raw = accumulated.isEmpty ? text : accumulated
        } else {
            raw = text
        }

        let processed = dictionaryService.apply(
            to: raw.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if settings.previewEnabled {
            transcriptionState = .done(processed)
            return
        }

        let app = targetApp
        targetApp = nil

        if let app, app.bundleIdentifier != Bundle.main.bundleIdentifier {
            app.activate(options: .activateIgnoringOtherApps)
            try? await Task.sleep(nanoseconds: 100_000_000)
            pasteService.paste(text: processed)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        historyService.add(text: processed)
        let styleName = selectedCustomStyle?.name ?? dictationStyle.rawValue
        statsService.record(text: processed, style: styleName, isTransform: false)
        transcriptionState = .idle
    }

    @MainActor
    func handleTransformDone(command: String) async {
        let original = selectedTextForTransform ?? ""
        selectedTextForTransform = nil

        let result: String
        if settings.llmProvider != .disabled, !original.isEmpty {
            let stream: AsyncThrowingStream<String, Error>
            do {
                stream = try LLMProcessorFactory.transformStream(
                    settings: settings,
                    original: original,
                    command: command
                )
            } catch let e as DictoError {
                transcriptionState = .error(e)
                return
            } catch {
                transcriptionState = .error(.ollamaNotReachable)
                return
            }
            guard let accumulated = await runLLMStream(stream) else { return }
            result = accumulated.isEmpty ? original : accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if !original.isEmpty {
            // KI deaktiviert, aber Text vorhanden → ohne Verarbeitung zeigen
            result = original
        } else {
            result = command
        }

        statsService.record(text: result, style: dictationStyle.rawValue, isTransform: true)
        isTransformResult = true
        transcriptionState = .done(result)
    }

    /// Streamt Tokens in `transcriptionState` und gibt den vollständigen Text zurück.
    /// Gibt `nil` zurück wenn ein Fehler auftrat (transcriptionState wurde auf .error gesetzt).
    @MainActor
    func runLLMStream(_ stream: AsyncThrowingStream<String, Error>) async -> String? {
        transcriptionState = .streaming("")
        var accumulated = ""
        do {
            for try await chunk in stream {
                accumulated += chunk
                transcriptionState = .streaming(accumulated)
            }
        } catch let e as DictoError {
            transcriptionState = .error(e)
            return nil
        } catch {
            transcriptionState = .error(.ollamaUnknown)
            return nil
        }
        return accumulated
    }
}
