import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enable in
                try? enable ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            }
        )
    }

    var body: some View {
        Form {
            // ── Sektion 1: Allgemein ──────────────────────────────────────────
            Section("Allgemein") {
                Toggle("Beim Login automatisch starten", isOn: launchAtLoginBinding)
                if SMAppService.mainApp.status == .requiresApproval {
                    Label {
                        Text("Bitte in Systemeinstellungen → Allgemein → Anmeldeobjekte genehmigen.")
                            .foregroundStyle(.orange)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                }
            }

            // ── Sektion 2: Sprache & Modell ───────────────────────────────────
            Section {
                Picker("Modell", selection: $settings.whisperModel) {
                    ForEach(WhisperModel.allCases, id: \.self) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.radioGroup)

                Text("Modellwechsel wird beim nächsten Diktat angewendet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Sprache", selection: $settings.whisperLanguage) {
                    ForEach(WhisperLanguage.allCases, id: \.self) { l in
                        Text(l.label).tag(l)
                    }
                }
                .pickerStyle(.radioGroup)
            } header: {
                Text("Sprache & Modell")
            }

            // ── Sektion 3: Verhalten ──────────────────────────────────────────
            Section {
                Toggle("Vorschau vor Einfügen", isOn: $settings.previewEnabled)
                Text("Text im Panel bearbeiten, bevor er eingefügt wird.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Verhalten")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
