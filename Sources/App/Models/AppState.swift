import AppKit
import Combine
import Foundation

enum MissingPermission {
    case none, inputMonitoring, microphone
}

final class AppState: ObservableObject {
    @Published private(set) var isRecording = false
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

    let hotkeyService: HotkeyService
    let audioService: AudioService
    let whisperService: WhisperService
    let pasteService: PasteService
    let settings = AppSettings()
    let dictionaryService = DictionaryService()

    var onOpenSettings: (() -> Void)?

    private var targetApp: NSRunningApplication?
    private var isTransformMode = false
    private var selectedTextForTransform: String?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let audio = AudioService()
        let hotkey = HotkeyService()
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

        hotkey.onKeyDown = { [weak self] in
            self?.targetApp = NSWorkspace.shared.frontmostApplication
            self?.isRecording = true
            audio.startRecording()
        }
        hotkey.onKeyUp = { [weak self] in
            guard let self else { return }
            self.isRecording = false
            let model = self.settings.whisperModel
            if let url = audio.stopRecording() {
                Task { await whisper.transcribe(fileURL: url, model: model) }
            }
        }

        hotkey.onTransformKeyDown = { [weak self] in
            guard let self else { return }
            self.targetApp = NSWorkspace.shared.frontmostApplication
            self.isTransformMode = true
            self.isRecording = true
            audio.startRecording()
            Task { @MainActor [weak self] in
                self?.selectedTextForTransform = await paste.captureSelectedText()
            }
        }
        hotkey.onTransformKeyUp = { [weak self] in
            guard let self else { return }
            self.isRecording = false
            let model = self.settings.whisperModel
            if let url = audio.stopRecording() {
                Task { await whisper.transcribe(fileURL: url, model: model) }
            }
        }

        Task { await whisper.loadModelIfNeeded(model: settings.whisperModel) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            paste.requestAccessibilityIfNeeded()
        }
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

        let effectivePrompt = dictationStyle.systemPrompt ?? settings.ollamaPrompt
        let processor: any TextPostProcessor = settings.ollamaEnabled
            ? OllamaPostProcessor(baseURL: settings.ollamaBaseURL, model: settings.ollamaModel, systemPrompt: effectivePrompt)
            : PassthroughPostProcessor()

        let processed = dictionaryService.apply(
            to: await processor.process(text: text)
                .trimmingCharacters(in: .whitespacesAndNewlines)
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

        transcriptionState = .done(processed)
    }

    @MainActor
    private func handleTransformDone(command: String) async {
        let original = selectedTextForTransform ?? ""
        selectedTextForTransform = nil

        let result: String
        if settings.ollamaEnabled, !original.isEmpty {
            let processor = OllamaTransformProcessor(
                baseURL: settings.ollamaBaseURL,
                model: settings.ollamaModel
            )
            result = await processor.process(original: original, command: command)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            result = command
        }

        let app = targetApp
        targetApp = nil

        if let app, app.bundleIdentifier != Bundle.main.bundleIdentifier {
            app.activate(options: .activateIgnoringOtherApps)
            try? await Task.sleep(nanoseconds: 100_000_000)
            pasteService.paste(text: result)
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        transcriptionState = .done(result)
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

        transcriptionState = .idle
    }
}
