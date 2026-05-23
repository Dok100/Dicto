import SwiftUI

struct AISettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var ollamaReachable: Bool? = nil
    @State private var editingStyle: CustomStyle? = nil

    var body: some View {
        Form {
            // ── Sektion 1: KI-Verarbeitung ────────────────────────────────────
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
                        Text("System-Prompt (Neutral)")
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

            // ── Sektion 2: Eigene Stile ───────────────────────────────────────
            Section {
                if settings.customStyles.isEmpty {
                    Text("Noch keine eigenen Stile angelegt.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(settings.customStyles) { style in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.name)
                                    .fontWeight(.medium)
                                Text(style.prompt.prefix(60) + (style.prompt.count > 60 ? "…" : ""))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button {
                                editingStyle = style
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation { deleteStyle(style) }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Button {
                    editingStyle = CustomStyle(name: "", prompt: AppSettings.defaultPrompt)
                } label: {
                    Label("Stil hinzufügen", systemImage: "plus.circle")
                }
                .font(.callout)
            } header: {
                Text("Eigene Stile")
            } footer: {
                Text("Eigene Stile erscheinen im Panel unterhalb der festen Stile und verwenden immer Ollama.")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $editingStyle) { style in
            CustomStyleEditView(style: style) { saved in
                if let idx = settings.customStyles.firstIndex(where: { $0.id == saved.id }) {
                    settings.customStyles[idx] = saved
                } else {
                    settings.customStyles.append(saved)
                }
                editingStyle = nil
            } onCancel: {
                editingStyle = nil
            }
        }
    }

    // MARK: – Hilfsmethoden

    private func deleteStyle(_ style: CustomStyle) {
        settings.customStyles.removeAll { $0.id == style.id }
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

// MARK: – Edit-Sheet

struct CustomStyleEditView: View {
    @State private var draft: CustomStyle
    let onSave: (CustomStyle) -> Void
    let onCancel: () -> Void

    init(style: CustomStyle, onSave: @escaping (CustomStyle) -> Void, onCancel: @escaping () -> Void) {
        _draft = State(initialValue: style)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    private var isNew: Bool { draft.name.isEmpty && draft.prompt == AppSettings.defaultPrompt }
    private var canSave: Bool { !draft.name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            // ── Titelzeile ──────────────────────────────────────────────────
            HStack {
                Button("Abbrechen", action: onCancel)
                Spacer()
                Text(isNew ? "Neuer Stil" : draft.name)
                    .fontWeight(.semibold)
                Spacer()
                Button("Speichern") { onSave(draft) }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
            .padding()

            Divider()

            // ── Formular ────────────────────────────────────────────────────
            Form {
                Section("Name") {
                    TextField("z.B. Arztbrief, WhatsApp, Protokoll", text: $draft.name)
                }
                Section {
                    TextEditor(text: $draft.prompt)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("System-Prompt")
                } footer: {
                    Text("Schreibe hier, wie der Text umgeformt werden soll. Der Diktat-Text wird automatisch in <diktat>…</diktat>-Tags eingebettet.")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 440)
    }
}
