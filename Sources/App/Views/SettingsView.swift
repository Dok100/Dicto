import SwiftUI
import ServiceManagement
import AppKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var dictionaryService: DictionaryService

    @State private var newWrong = ""
    @State private var newCorrect = ""
    @State private var ollamaReachable: Bool? = nil

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
            // ── Sektion 1: Allgemein ─────────────────────────────────────────
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

            // ── Sektion 2: Sprache & Modell ──────────────────────────────────
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

            // ── Sektion 3: Verhalten ─────────────────────────────────────────
            Section {
                Toggle("Vorschau vor Einfügen", isOn: $settings.previewEnabled)
                Text("Text im Panel bearbeiten, bevor er eingefügt wird.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Verhalten")
            }

            // ── Sektion 4: KI-Verarbeitung (Ollama) ──────────────────────────
            Section {
                HStack {
                    Toggle("Textglättung via Ollama", isOn: $settings.ollamaEnabled)
                    if settings.ollamaEnabled {
                        Spacer()
                        ollamaStatusDot
                    }
                }
                .task(id: settings.ollamaEnabled) {
                    guard settings.ollamaEnabled else { ollamaReachable = nil; return }
                    await checkOllama()
                }

                if settings.ollamaEnabled {
                    LabeledContent("Modell") {
                        TextField("glm4", text: $settings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                    }
                    LabeledContent("Endpoint") {
                        TextField("http://localhost:11434", text: $settings.ollamaBaseURL)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("System-Prompt")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextEditor(text: $settings.ollamaPrompt)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 160)
                            .scrollContentBackground(.hidden)
                            .padding(6)
                            .background(.quinary, in: RoundedRectangle(cornerRadius: 6))
                        Button("Auf Standard zurücksetzen") {
                            settings.ollamaPrompt = AppSettings.defaultPrompt
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("KI-Verarbeitung")
            }

            // ── Sektion 5: Wörterbuch ────────────────────────────────────────
            Section {
                Text("Falsch erkannte Wörter automatisch ersetzen. Korrekturen im Vorschau-Modus werden automatisch gelernt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !dictionaryService.entries.isEmpty {
                    ForEach(dictionaryService.entries) { entry in
                        HStack(spacing: 8) {
                            Text(entry.wrong)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text(entry.correct)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                dictionaryService.remove(id: entry.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.callout)
                    }
                }

                // Neuen Eintrag hinzufügen
                HStack(spacing: 6) {
                    TextField("Falsch", text: $newWrong)
                        .textFieldStyle(.roundedBorder)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                    TextField("Richtig", text: $newCorrect)
                        .textFieldStyle(.roundedBorder)
                    Button("Hinzufügen") {
                        dictionaryService.add(wrong: newWrong, correct: newCorrect)
                        newWrong = ""
                        newCorrect = ""
                    }
                    .disabled(
                        newWrong.trimmingCharacters(in: .whitespaces).isEmpty ||
                        newCorrect.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }

                HStack(spacing: 8) {
                    Button("Exportieren") { exportDictionary() }
                    Button("Importieren") { importDictionary() }
                }
                .font(.caption)
            } header: {
                Text("Wörterbuch")
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 420, minHeight: 480)
    }

    // MARK: – Ollama-Status-Dot

    @ViewBuilder
    private var ollamaStatusDot: some View {
        switch ollamaReachable {
        case .none:
            ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
        case .some(true):
            Image(systemName: "circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
                .help("Ollama erreichbar")
        case .some(false):
            Image(systemName: "circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
                .help("Ollama nicht erreichbar – läuft der Server?")
        }
    }

    // MARK: – Export / Import

    private func exportDictionary() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "dicto-woerterbuch.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let data = try? JSONEncoder().encode(dictionaryService.entries) {
                try? data.write(to: url)
            }
        }
    }

    private func importDictionary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let data = try? Data(contentsOf: url),
                  let entries = try? JSONDecoder().decode([WordEntry].self, from: data)
            else { return }
            for entry in entries {
                dictionaryService.add(wrong: entry.wrong, correct: entry.correct)
            }
        }
    }

    // MARK: – Ollama-Verbindung prüfen

    private func checkOllama() async {
        ollamaReachable = nil
        guard let url = URL(string: settings.ollamaBaseURL) else { ollamaReachable = false; return }
        do {
            let (_, response) = try await URLSession.shared.data(
                for: URLRequest(url: url, timeoutInterval: 3)
            )
            ollamaReachable = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            ollamaReachable = false
        }
    }
}
