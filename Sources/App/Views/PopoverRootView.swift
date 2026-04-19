import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            statusIcon
            Text("Dicto").font(.headline)
            statusText
            Spacer()
            Divider()
            Button("Beenden") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 280, height: 200)
    }

    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: appState.isRecording ? "mic.fill" : "mic")
            .font(.system(size: 36))
            .foregroundStyle(appState.isRecording ? Color.red : Color.secondary)
            .animation(.easeInOut(duration: 0.15), value: appState.isRecording)
    }

    @ViewBuilder
    private var statusText: some View {
        switch appState.missingPermission {
        case .accessibility:
            PermissionHint(
                message: "Bedienungshilfen-Zugriff fehlt.",
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
                appState: appState
            )
        case .inputMonitoring:
            PermissionHint(
                message: "Eingabe-Überwachung fehlt.",
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
                appState: appState
            )
        case .microphone:
            PermissionHint(
                message: "Mikrofon-Zugriff fehlt.",
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
                appState: appState
            )
        case .none:
            if appState.isRecording {
                Text("Aufnahme läuft …").font(.subheadline).foregroundStyle(.red)
            } else {
                Text("Fn gedrückt halten zum Diktieren").font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

private struct PermissionHint: View {
    let message: String
    let settingsURL: String
    let appState: AppState

    var body: some View {
        VStack(spacing: 6) {
            Text(message).font(.caption).foregroundStyle(.orange)
            HStack(spacing: 8) {
                Button("Einstellungen öffnen") {
                    if let url = URL(string: settingsURL) {
                        NSWorkspace.shared.open(url)
                    }
                }
                .font(.caption)
                Button("Neu prüfen") {
                    appState.recheckPermissions()
                }
                .font(.caption)
            }
        }
    }
}
