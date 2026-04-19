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

    let hotkeyService: HotkeyService
    let audioService: AudioService
    let whisperService: WhisperService
    let pasteService: PasteService

    private var targetApp: NSRunningApplication?
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

        // WhisperService.state weiterleiten – .done abfangen für Text-Einfügung
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
            // Aktive App merken, damit wir nach der Transkription dorthin einfügen
            self?.targetApp = NSWorkspace.shared.frontmostApplication
            self?.isRecording = true
            audio.startRecording()
        }
        hotkey.onKeyUp = { [weak self] in
            guard let self else { return }
            self.isRecording = false
            if let url = audio.stopRecording() {
                Task { await whisper.transcribe(fileURL: url) }
            }
        }

        Task { await whisper.loadModelIfNeeded() }
    }

    func recheckPermissions() {
        hotkeyService.retryIfNeeded()
        hasMicrophonePermission = audioService.isMicrophoneAuthorized
        objectWillChange.send()
    }

    // MARK: – Text-Einfügung

    @MainActor
    private func handleTranscriptionDone(text: String) async {
        let app = targetApp
        targetApp = nil

        // Nur in externe Apps einfügen (nicht in Dicto selbst)
        if let app, app.bundleIdentifier != Bundle.main.bundleIdentifier {
            app.activate(options: .activateIgnoringOtherApps)
            // Kurze Pause damit die Ziel-App den Fokus bekommt
            try? await Task.sleep(nanoseconds: 100_000_000)
            pasteService.paste(text: text)
            // Pause damit Cmd+V verarbeitet wird, bevor der Popover den Fokus übernimmt
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        transcriptionState = .done(text)
    }
}
