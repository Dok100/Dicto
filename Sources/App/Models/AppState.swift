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
        let raw = UserDefaults.standard.string(forKey: "dictationStyle") ?? ""
        return DictationStyle(rawValue: raw) ?? .neutral
    }() {
        didSet { UserDefaults.standard.set(dictationStyle.rawValue, forKey: "dictationStyle") }
    }

    /// Aktiver eigener Stil – überschreibt `dictationStyle` wenn gesetzt.
    @Published private(set) var selectedCustomStyle: CustomStyle?

    /// Fixen Stil wählen und eigenen Stil abwählen.
    func selectFixedStyle(_ style: DictationStyle) {
        dictationStyle = style
        selectedCustomStyle = nil
    }

    /// Eigenen Stil wählen.
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

    private var targetApp: NSRunningApplication?
    @Published private(set) var isTransformMode = false
    @Published private(set) var isTransformResult = false
    private var selectedTextForTransform: String?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let audio = AudioService()
        let hotkey = HotkeyService(
            dictation: settings.dictationShortcut,
            transform: settings.transformShortcut
        )
        let whisper = WhisperService()
        let paste = PasteService()
        self.audioService = audio
        self.hotkeyService = hotkey
        self.whisperService = whisper
        self.pasteService = paste
        self.hasMicrophonePermission = audio.isMicrophoneAuthorized

        whisper.$state
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

        audio.requestPermissionIfNeeded { [weak self] granted in
            DispatchQueue.main.async { self?.hasMicrophonePermission = granted }
        }

        // Apple Speech Callbacks – feuern auf beliebigem Thread
        appleSpeechService.onPartialResult = { [weak self] text in
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }
                // Nur anzeigen wenn kein Ollama danach folgt – sonst würde der
                // Rohtext und der geglättete Text nacheinander streamen (doppelt).
                let useOllama = self.settings.ollamaEnabled || self.selectedCustomStyle != nil
                if !useOllama {
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
                self.transcriptionState = .error(DictoError.appleSpeechUnavailable.displayMessage)
            }
        }

        hotkey.onKeyDown = { [weak self] in
            guard let self else { return }
            self.targetApp = NSWorkspace.shared.frontmostApplication
            self.isRecording = true
            if settings.soundFeedbackEnabled { SoundFeedback.playStart() }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.startRecording(locale: settings.whisperLanguage.appleLocale)
            } else {
                audio.startRecording()
            }
        }
        hotkey.onKeyUp = { [weak self] in
            guard let self else { return }
            if settings.soundFeedbackEnabled { SoundFeedback.playStop() }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.stopRecording()
                // isRecording wird in onFinalResult zurückgesetzt
            } else {
                self.isRecording = false
                let model = self.settings.whisperModel
                let language = self.settings.whisperLanguage
                if let url = audio.stopRecording() {
                    Task { await whisper.transcribe(fileURL: url, model: model, language: language) }
                }
            }
        }

        hotkey.onTransformKeyDown = { [weak self] in
            guard let self else { return }
            self.targetApp = NSWorkspace.shared.frontmostApplication
            self.isTransformMode = true
            self.isRecording = true
            self.isTransformRecording = true
            if settings.soundFeedbackEnabled { SoundFeedback.playStart() }
            Task { @MainActor [weak self] in
                self?.selectedTextForTransform = await paste.captureSelectedText()
            }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.startRecording(locale: settings.whisperLanguage.appleLocale)
            } else {
                audio.startRecording()
            }
        }
        hotkey.onTransformKeyUp = { [weak self] in
            guard let self else { return }
            if settings.soundFeedbackEnabled { SoundFeedback.playStop() }
            if settings.transcriptionEngine == .apple {
                appleSpeechService.stopRecording()
                // isRecording/isTransformRecording werden in onFinalResult zurückgesetzt
            } else {
                self.isRecording = false
                self.isTransformRecording = false
                let model = self.settings.whisperModel
                let language = self.settings.whisperLanguage
                if let url = audio.stopRecording() {
                    Task { await whisper.transcribe(fileURL: url, model: model, language: language) }
                }
            }
        }

        // Settings-Änderungen an AppState.objectWillChange weiterleiten,
        // damit alle Views (z.B. PopoverRootView) neu rendern wenn sich
        // customStyles, ollamaEnabled etc. ändern.
        settings.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Shortcut-Änderungen aus Settings → HotkeyService weiterleiten
        settings.$dictationShortcut
            .dropFirst()
            .sink { [weak hotkey] config in hotkey?.dictationShortcut = config }
            .store(in: &cancellables)
        settings.$transformShortcut
            .dropFirst()
            .sink { [weak hotkey] config in hotkey?.transformShortcut = config }
            .store(in: &cancellables)

        Task { await whisper.loadModelIfNeeded(model: settings.whisperModel) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            paste.requestAccessibilityIfNeeded()
        }
        // Apple Speech Permission vorab anfragen (nur Dialog, kein Zwang)
        appleSpeechService.requestAuthorization { _ in }
    }

    func recheckPermissions() {
        hotkeyService.retryIfNeeded()
        hasMicrophonePermission = audioService.isMicrophoneAuthorized
        pasteService.requestAccessibilityIfNeeded()
        objectWillChange.send()
    }

    // MARK: – Text-Einfügung

    @MainActor
    private func handleTranscriptionDone(text: String) async {
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
        let useOllama = settings.ollamaEnabled || selectedCustomStyle != nil

        let raw: String
        if useOllama {
            let stream: AsyncThrowingStream<String, Error>
            do {
                switch settings.llmProvider {
                case .ollama:
                    stream = try OllamaPostProcessor(
                        baseURL: settings.ollamaBaseURL,
                        model: settings.ollamaModel,
                        systemPrompt: effectivePrompt
                    ).streamProcess(text: text)
                case .openAI:
                    stream = try OpenAIPostProcessor(
                        baseURL: settings.openAIBaseURL,
                        apiKey: settings.openAIApiKey,
                        model: settings.openAIModel,
                        systemPrompt: effectivePrompt
                    ).streamProcess(text: text)
                }
            } catch let e as DictoError {
                transcriptionState = .error(e.displayMessage)
                return
            } catch {
                transcriptionState = .error(DictoError.ollamaNotReachable.displayMessage)
                return
            }
            transcriptionState = .streaming("")
            var accumulated = ""
            do {
                for try await chunk in stream {
                    accumulated += chunk
                    transcriptionState = .streaming(accumulated)
                }
            } catch let e as DictoError {
                transcriptionState = .error(e.displayMessage)
                return
            } catch {
                transcriptionState = .error(DictoError.ollamaUnknown.displayMessage)
                return
            }
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
    private func handleTransformDone(command: String) async {
        let original = selectedTextForTransform ?? ""
        selectedTextForTransform = nil

        let result: String
        if settings.ollamaEnabled, !original.isEmpty {
            let stream: AsyncThrowingStream<String, Error>
            do {
                switch settings.llmProvider {
                case .ollama:
                    stream = try OllamaTransformProcessor(
                        baseURL: settings.ollamaBaseURL,
                        model: settings.ollamaModel
                    ).streamProcess(original: original, command: command)
                case .openAI:
                    stream = try OpenAITransformProcessor(
                        baseURL: settings.openAIBaseURL,
                        apiKey: settings.openAIApiKey,
                        model: settings.openAIModel
                    ).streamProcess(original: original, command: command)
                }
            } catch let e as DictoError {
                transcriptionState = .error(e.displayMessage)
                return
            } catch {
                transcriptionState = .error(DictoError.ollamaNotReachable.displayMessage)
                return
            }
            transcriptionState = .streaming("")
            var accumulated = ""
            do {
                for try await chunk in stream {
                    accumulated += chunk
                    transcriptionState = .streaming(accumulated)
                }
            } catch let e as DictoError {
                transcriptionState = .error(e.displayMessage)
                return
            } catch {
                transcriptionState = .error(DictoError.ollamaUnknown.displayMessage)
                return
            }
            result = accumulated.isEmpty ? original : accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if !original.isEmpty {
            // Ollama deaktiviert, aber Text vorhanden → ohne KI-Verarbeitung zeigen
            result = original
        } else {
            result = command
        }

        // Transform zeigt immer Vorschau – Auto-Einfügen ergibt im Transform-Modus keinen Sinn
        statsService.record(text: result, style: dictationStyle.rawValue, isTransform: true)
        isTransformResult = true
        transcriptionState = .done(result)
    }

    @MainActor
    func dismissResult() {
        isTransformResult = false
        transcriptionState = .idle
    }

    @MainActor
    func dismissError() {
        transcriptionState = .idle
    }

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
