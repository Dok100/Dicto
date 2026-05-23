import SwiftUI

struct AISettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var ollamaReachable: Bool? = nil

    var body: some View {
        Form {
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
                            .frame(minHeight: 180)
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
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
