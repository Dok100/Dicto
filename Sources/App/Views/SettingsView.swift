import SwiftUI
import ServiceManagement

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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Beim Login automatisch starten", isOn: launchAtLoginBinding)
                    .toggleStyle(.switch)
                if SMAppService.mainApp.status == .requiresApproval {
                    Text("Bitte in Systemeinstellungen → Allgemein → Anmeldeobjekte genehmigen.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Divider()

                Text("Whisper-Modell").font(.headline)
                Picker("Modell", selection: $settings.whisperModel) {
                    ForEach(WhisperModel.allCases, id: \.self) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                Text("Modellwechsel wird beim nächsten Diktat angewendet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Sprache", selection: $settings.whisperLanguage) {
                    ForEach(WhisperLanguage.allCases, id: \.self) { l in
                        Text(l.label).tag(l)
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                Divider()

                Toggle("Vorschau vor Einfügen", isOn: $settings.previewEnabled)
                    .toggleStyle(.switch)
                Text("Text im Popover bearbeiten, bevor er eingefügt wird.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                HStack(spacing: 8) {
                    Toggle("Textglättung via Ollama", isOn: $settings.ollamaEnabled)
                        .toggleStyle(.switch)
                    if settings.ollamaEnabled {
                        ollamaStatusDot
                    }
                }
                .task(id: settings.ollamaEnabled) {
                    guard settings.ollamaEnabled else { ollamaReachable = nil; return }
                    await checkOllama()
                }

                if settings.ollamaEnabled {
                    Divider()

                    Group {
                        row(label: "Modell") {
                            TextField("glm4", text: $settings.ollamaModel)
                                .textFieldStyle(.roundedBorder)
                        }
                        row(label: "Endpoint") {
                            TextField("http://localhost:11434", text: $settings.ollamaBaseURL)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Divider()

                    Text("System-Prompt").font(.headline)

                    TextEditor(text: $settings.ollamaPrompt)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 220)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))

                    Button("Auf Standard zurücksetzen") {
                        settings.ollamaPrompt = AppSettings.defaultPrompt
                    }
                    .font(.caption)
                }

                Divider()

                Text("Wörterbuch").font(.headline)
                Text("Falsch erkannte Wörter automatisch ersetzen. Korrekturen im Vorschau-Modus werden automatisch gelernt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if dictionaryService.entries.isEmpty {
                    Text("Noch keine Einträge.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(dictionaryService.entries) { entry in
                            HStack(spacing: 8) {
                                Text(entry.wrong)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "arrow.right")
                                    .foregroundStyle(.secondary)
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
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            Divider()
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
                }

                HStack(spacing: 6) {
                    TextField("Falsch", text: $newWrong)
                        .textFieldStyle(.roundedBorder)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    TextField("Richtig", text: $newCorrect)
                        .textFieldStyle(.roundedBorder)
                    Button("Hinzufügen") {
                        dictionaryService.add(wrong: newWrong, correct: newCorrect)
                        newWrong = ""
                        newCorrect = ""
                    }
                    .disabled(newWrong.trimmingCharacters(in: .whitespaces).isEmpty ||
                              newCorrect.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 400, minHeight: 400)
    }

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .frame(width: 70, alignment: .trailing)
                .foregroundStyle(.secondary)
            content()
        }
    }

    @ViewBuilder
    private var ollamaStatusDot: some View {
        switch ollamaReachable {
        case .none:
            ProgressView().scaleEffect(0.5).frame(width: 14, height: 14)
        case .some(true):
            Image(systemName: "circle.fill").foregroundStyle(.green).font(.caption)
                .help("Ollama erreichbar")
        case .some(false):
            Image(systemName: "circle.fill").foregroundStyle(.red).font(.caption)
                .help("Ollama nicht erreichbar – läuft der Server?")
        }
    }

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
