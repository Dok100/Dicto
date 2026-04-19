import Foundation

final class AppState: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var hasHotkeyPermission = false
    @Published private(set) var hasMicrophonePermission = false

    let hotkeyService: HotkeyService
    let audioService: AudioService

    init() {
        let audio = AudioService()
        let hotkey = HotkeyService()
        self.audioService = audio
        self.hotkeyService = hotkey
        self.hasHotkeyPermission = hotkey.isAvailable
        self.hasMicrophonePermission = audio.isMicrophoneAuthorized

        // Mikrofon-Permission sofort beim Start anfragen, nicht erst beim ersten Record.
        // So ist die Permission schon erteilt, wenn der Nutzer das erste Mal Fn drückt.
        audio.requestPermissionIfNeeded { [weak self] granted in
            DispatchQueue.main.async {
                self?.hasMicrophonePermission = granted
            }
        }

        hotkey.onKeyDown = { [weak self] in
            self?.isRecording = true
            audio.startRecording()
        }
        hotkey.onKeyUp = { [weak self] in
            self?.isRecording = false
            audio.stopRecording()
        }
    }
}
