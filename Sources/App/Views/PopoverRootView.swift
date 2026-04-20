import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 10) {
            statusIcon
            Text("Dicto").font(.headline)
            statusArea
            Spacer(minLength: 0)
            Picker("Stil", selection: $appState.dictationStyle) {
                ForEach(DictationStyle.allCases, id: \.self) { style in
                    Text(style.label).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(appState.isRecording)
            Divider()
            HStack {
                Button(action: { appState.onOpenSettings?() }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help("Einstellungen")
                Spacer()
                Button("Beenden") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding()
        .frame(width: 280, height: 270)
    }

    // MARK: – Status-Icon

    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: iconName)
            .font(.system(size: 32))
            .foregroundStyle(iconColor)
            .animation(.easeInOut(duration: 0.15), value: appState.isRecording)
    }

    private var iconName: String {
        appState.isRecording ? "mic.fill" : "mic"
    }

    private var iconColor: Color {
        appState.isRecording ? .red : .secondary
    }

    // MARK: – Haupt-Statusbereich

    @ViewBuilder
    private var statusArea: some View {
        switch appState.missingPermission {
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
            transcriptionArea
        }
    }

    // MARK: – Transkriptions-Bereich

    @ViewBuilder
    private var transcriptionArea: some View {
        switch appState.transcriptionState {
        case .idle:
            if appState.isRecording {
                Text("Aufnahme läuft …").font(.subheadline).foregroundStyle(.red)
            } else {
                Text("Fn gedrückt halten zum Diktieren")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

        case .loadingModel(let progress):
            VStack(spacing: 4) {
                if progress > 0 {
                    ProgressView(value: progress).progressViewStyle(.linear)
                } else {
                    ProgressView().progressViewStyle(.circular).scaleEffect(0.7)
                }
                Text(progress > 0
                    ? "Modell wird geladen … \(Int(progress * 100)) %"
                    : "Modell wird geladen …")
                    .font(.caption).foregroundStyle(.secondary)
            }

        case .transcribing:
            VStack(spacing: 4) {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.7)
                Text("Transkribiere …").font(.caption).foregroundStyle(.secondary)
            }

        case .done(let text):
            VStack(spacing: 6) {
                ScrollView {
                    Text(text)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 80)
                if !appState.isAccessibilityAuthorized {
                    PermissionHint(
                        message: "Eingabehilfen fehlt – Text nicht eingefügt.",
                        settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
                        appState: appState
                    )
                }
            }

        case .error(let message):
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: – Berechtigungs-Hinweis

private struct PermissionHint: View {
    let message: String
    let settingsURL: String
    let appState: AppState

    var body: some View {
        VStack(spacing: 6) {
            Text(message).font(.caption).foregroundStyle(.orange)
            HStack(spacing: 8) {
                Button("Einstellungen öffnen") {
                    if let url = URL(string: settingsURL) { NSWorkspace.shared.open(url) }
                }
                .font(.caption)
                Button("Neu prüfen") { appState.recheckPermissions() }
                    .font(.caption)
            }
        }
    }
}
