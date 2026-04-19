import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Toggle("Textglättung via Ollama", isOn: $settings.ollamaEnabled)
                    .toggleStyle(.switch)

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

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(width: 480, height: 520)
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
}
