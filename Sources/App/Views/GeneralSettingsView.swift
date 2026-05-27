import ServiceManagement
import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enable in
                try? enable ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            })
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

            // ── Sektion 2: Spracherkennungs-Engine ───────────────────────────
            Section {
                Picker("Engine", selection: $settings.transcriptionEngine) {
                    ForEach(TranscriptionEngine.allCases, id: \.self) { e in
                        Text(e.label).tag(e)
                    }
                }
                .pickerStyle(.radioGroup)

                if settings.transcriptionEngine == .apple {
                    Label(
                        "Text erscheint live während du sprichst. Vollständig lokal – kein Download nötig.",
                        systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Spracherkennung")
            }

            // ── Sektion 3: Sprache & Whisper-Modell ──────────────────────────
            Section {
                Picker("Sprache", selection: $settings.whisperLanguage) {
                    ForEach(WhisperLanguage.allCases, id: \.self) { l in
                        Text(l.label).tag(l)
                    }
                }
                .pickerStyle(.radioGroup)

                if settings.transcriptionEngine == .whisper {
                    Picker("Whisper-Modell", selection: $settings.whisperModel) {
                        ForEach(WhisperModel.allCases, id: \.self) { m in
                            HStack {
                                Text(m.label)
                                if m.isProFeature && !LicenseService.shared.isPro {
                                    Image(systemName: "lock.fill")
                                }
                            }.tag(m)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text("Modellwechsel wird beim nächsten Diktat angewendet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Sprache & Modell")
            }

            // ── Sektion 3: Verhalten ──────────────────────────────────────────
            Section {
                Toggle("Vorschau vor Einfügen", isOn: $settings.previewEnabled)
                Text("Text im Panel bearbeiten, bevor er eingefügt wird.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Sound-Feedback", isOn: $settings.soundFeedbackEnabled)
                Text("Kurzes Klicken beim Start und sanftes Pop beim Stopp der Aufnahme.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Verhalten")
            }

            // ── Sektion 4: Tastaturkürzel ─────────────────────────────────────
            Section {
                ShortcutRecorderView(label: "Diktieren", shortcut: $settings.dictationShortcut)
                ShortcutRecorderView(label: "Transformieren", shortcut: $settings.transformShortcut)

                Text(
                    "Fn-Taste allein oder mit Modifier: halten zum Aufnehmen, loslassen zum Stoppen. Normale Tasten: mindestens einen Modifier (⌘ ⌥ ⌃ ⇧) halten.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Auf Standard zurücksetzen") {
                    settings.dictationShortcut = .defaultDictation
                    settings.transformShortcut = .defaultTransform
                }
                .font(.caption)
            } header: {
                Text("Tastaturkürzel")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
