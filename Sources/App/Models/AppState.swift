import Foundation

final class AppState: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var hasHotkeyPermission = false

    let hotkeyService: HotkeyService
    let audioService: AudioService

    init() {
        let audio = AudioService()
        let hotkey = HotkeyService()
        self.audioService = audio
        self.hotkeyService = hotkey
        self.hasHotkeyPermission = hotkey.isAvailable

        // HotkeyService-Callbacks laufen bereits auf dem Main Thread (RunLoop-Source)
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
