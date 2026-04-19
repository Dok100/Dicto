import Foundation

enum MissingPermission {
    case none, accessibility, inputMonitoring, microphone
}

final class AppState: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var hasMicrophonePermission = false

    // Welche Berechtigung fehlt gerade – treibt die Popover-Anzeige
    var missingPermission: MissingPermission {
        if !hotkeyService.isAvailable { return .inputMonitoring }
        if !audioService.isMicrophoneAuthorized { return .microphone }
        return .none
    }

    let hotkeyService: HotkeyService
    let audioService: AudioService

    init() {
        let audio = AudioService()
        let hotkey = HotkeyService()
        self.audioService = audio
        self.hotkeyService = hotkey
        self.hasMicrophonePermission = audio.isMicrophoneAuthorized

        audio.requestPermissionIfNeeded { [weak self] granted in
            DispatchQueue.main.async { self?.hasMicrophonePermission = granted }
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

    func recheckPermissions() {
        hotkeyService.retryIfNeeded()
        hasMicrophonePermission = audioService.isMicrophoneAuthorized
        objectWillChange.send()
    }
}
