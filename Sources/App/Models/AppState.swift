import Combine
import Foundation

enum MissingPermission {
    case none, inputMonitoring, microphone
}

final class AppState: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var hasMicrophonePermission = false
    // Leitet WhisperService.state durch, damit der Popover automatisch reagiert
    @Published private(set) var transcriptionState: TranscriptionState = .idle

    var missingPermission: MissingPermission {
        if !hotkeyService.isAvailable { return .inputMonitoring }
        if !audioService.isMicrophoneAuthorized { return .microphone }
        return .none
    }

    let hotkeyService: HotkeyService
    let audioService: AudioService
    let whisperService: WhisperService

    private var cancellables = Set<AnyCancellable>()

    init() {
        let audio = AudioService()
        let hotkey = HotkeyService()
        let whisper = WhisperService()
        self.audioService = audio
        self.hotkeyService = hotkey
        self.whisperService = whisper
        self.hasMicrophonePermission = audio.isMicrophoneAuthorized

        // WhisperService.state → AppState.transcriptionState weiterleiten
        // Combine: receive(on:) stellt sicher dass wir auf dem Main Thread sind
        whisper.$state
            .receive(on: RunLoop.main)
            .assign(to: \.transcriptionState, on: self)
            .store(in: &cancellables)

        audio.requestPermissionIfNeeded { [weak self] granted in
            DispatchQueue.main.async { self?.hasMicrophonePermission = granted }
        }

        hotkey.onKeyDown = { [weak self] in
            self?.isRecording = true
            audio.startRecording()
        }
        hotkey.onKeyUp = { [weak self] in
            guard let self else { return }
            self.isRecording = false
            if let url = audio.stopRecording() {
                // Task { } startet eine asynchrone Aufgabe – nötig weil transcribe()
                // eine async-Funktion ist, die man nicht direkt aus einem Closure aufrufen kann
                Task { await whisper.transcribe(fileURL: url) }
            }
        }

        // Modell sofort beim Start laden, damit es beim ersten Diktat bereit ist
        Task { await whisper.loadModelIfNeeded() }
    }

    func recheckPermissions() {
        hotkeyService.retryIfNeeded()
        hasMicrophonePermission = audioService.isMicrophoneAuthorized
        objectWillChange.send()
    }
}
