import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Textglättung via Ollama", isOn: $settings.ollamaEnabled)
            }

            if settings.ollamaEnabled {
                Section("Ollama-Verbindung") {
                    LabeledContent("Modell") {
                        TextField("glm4", text: $settings.ollamaModel)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                    LabeledContent("Endpoint") {
                        TextField("http://localhost:11434", text: $settings.ollamaBaseURL)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                    }
                }

                Section("System-Prompt") {
                    TextEditor(text: $settings.ollamaPrompt)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                        .border(Color.secondary.opacity(0.3))

                    Button("Auf Standard zurücksetzen") {
                        settings.ollamaPrompt = AppSettings.defaultPrompt
                    }
                    .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480)
    }
}
