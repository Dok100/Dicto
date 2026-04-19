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
        if !appState.hasHotkeyPermission {
            VStack(spacing: 6) {
                Text("Bedienungshilfen-Zugriff fehlt.\nSystemeinstellungen → Datenschutz → Bedienungshilfen")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                Button("Neu prüfen") {
                    appState.recheckPermissions()
                }
                .font(.caption)
            }
        } else if !appState.hasMicrophonePermission {
            VStack(spacing: 6) {
                Text("Mikrofon-Zugriff fehlt.\nSystemeinstellungen → Datenschutz → Mikrofon")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                Button("Neu prüfen") {
                    appState.recheckPermissions()
                }
                .font(.caption)
            }
        } else if appState.isRecording {
            Text("Aufnahme läuft …")
                .font(.subheadline)
                .foregroundStyle(.red)
        } else {
            Text("Fn gedrückt halten zum Diktieren")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
