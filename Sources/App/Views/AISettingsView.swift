import SwiftUI

struct AISettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var ollamaReachable: Bool? = nil
    @State private var availableModels: [String] = []
    @State private var loadingModels = false
    @State private var editingStyle: CustomStyle? = nil

    // API-Key wird in @State gehalten (Keychain-backed Property ist nicht @Published)
    @State private var openAIApiKey: String = ""
    @State private var showApiKey: Bool = false

    /// Merkt sich den zuletzt aktiven Provider damit beim Reaktivieren wiederhergestellt wird
    @State private var lastActiveProvider: LLMProvider = .ollama

    /// Binding für den KI-aktiv-Toggle: schaltet zwischen .disabled und lastActiveProvider um
    private var llmEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings.llmProvider != .disabled },
            set: { enabled in
                if enabled {
                    settings.llmProvider = lastActiveProvider
                } else {
                    lastActiveProvider = settings.llmProvider // vor dem Deaktivieren merken
                    settings.llmProvider = .disabled
                }
            })
    }

    var body: some View {
        Form {
            // ── Sektion 1: KI-Verarbeitung ────────────────────────────────────
            Section {
                HStack {
                    Toggle("Textglättung via KI", isOn: llmEnabledBinding)
                    if settings.llmEnabled {
                        Spacer()
                        llmStatusDot
                    }
                }
                .task(id: settings.llmProvider) {
                    guard settings.llmEnabled else { ollamaReachable = nil; return }
                    if settings.llmProvider == .ollama { await checkOllama() }
                    else { ollamaReachable = nil }
                }

                if settings.llmEnabled {
                    // ── Anbieter-Picker (.disabled wird nicht angeboten) ──────
                    Picker("Anbieter", selection: $settings.llmProvider) {
                        ForEach(LLMProvider.activeProviders, id: \.self) { provider in
                            Text(provider.label).tag(provider)
                        }
                    }

                    // ── Anbieter-spezifische Einstellungen ────────────────────
                    switch settings.llmProvider {
                    case .disabled: EmptyView() // nie sichtbar – llmEnabled-Guard oben
                    case .ollama: ollamaSettings
                    case .openAI: openAISettings
                    }

                    // ── System-Prompt (geteilt) ───────────────────────────────
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
                Text(
                    "Eigene Stile erscheinen im Panel unterhalb der festen Stile und verwenden immer den konfigurierten KI-Anbieter.")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            openAIApiKey = settings.openAIApiKey
            if settings.llmEnabled { lastActiveProvider = settings.llmProvider }
        }
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

    // MARK: – Ollama-Einstellungen

    @ViewBuilder
    private var ollamaSettings: some View {
        LabeledContent("Modell") {
            if availableModels.isEmpty {
                HStack(spacing: 6) {
                    TextField("glm4", text: $settings.ollamaModel)
                        .textFieldStyle(.roundedBorder)
                    if loadingModels {
                        ProgressView().scaleEffect(0.6).frame(width: 14, height: 14)
                    }
                }
            } else {
                Picker("", selection: $settings.ollamaModel) {
                    ForEach(availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                    if !availableModels.contains(settings.ollamaModel) {
                        Text(settings.ollamaModel + " (manuell)").tag(settings.ollamaModel)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .task(id: settings.ollamaBaseURL) {
            await fetchModels()
        }
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent("Endpoint") {
                TextField("http://localhost:11434", text: $settings.ollamaBaseURL)
                    .textFieldStyle(.roundedBorder)
            }
            if !isValidOllamaURL {
                Label(
                    "Ungültige URL – bitte http:// oder https:// verwenden.",
                    systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: – OpenAI-Einstellungen

    @ViewBuilder
    private var openAISettings: some View {
        LabeledContent("API-Key") {
            HStack(spacing: 6) {
                if showApiKey {
                    TextField("sk-…", text: $openAIApiKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("sk-…", text: $openAIApiKey)
                        .textFieldStyle(.roundedBorder)
                }
                Button {
                    showApiKey.toggle()
                } label: {
                    Image(systemName: showApiKey ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(showApiKey ? "API-Key verbergen" : "API-Key anzeigen")
            }
            .onChange(of: openAIApiKey) { _, new in
                settings.openAIApiKey = new // sofort in Keychain schreiben
            }
        }
        LabeledContent("Modell") {
            TextField("gpt-4o-mini", text: $settings.openAIModel)
                .textFieldStyle(.roundedBorder)
        }
        VStack(alignment: .leading, spacing: 4) {
            LabeledContent("Basis-URL") {
                TextField("https://api.openai.com/v1", text: $settings.openAIBaseURL)
                    .textFieldStyle(.roundedBorder)
            }
            Text("Kompatibel mit OpenAI-Proxies, Groq, LM Studio u.a.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !isValidOpenAIURL {
                Label(
                    "Ungültige URL – bitte http:// oder https:// verwenden.",
                    systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: – Hilfsmethoden

    private var isValidOllamaURL: Bool {
        guard let url = URL(string: settings.ollamaBaseURL),
              let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    private var isValidOpenAIURL: Bool {
        guard let url = URL(string: settings.openAIBaseURL),
              let scheme = url.scheme else { return false }
        return scheme == "http" || scheme == "https"
    }

    private func deleteStyle(_ style: CustomStyle) {
        settings.customStyles.removeAll { $0.id == style.id }
    }

    // MARK: – Status-Dot

    @ViewBuilder
    private var llmStatusDot: some View {
        // Nur bei Ollama zeigen wir einen Erreichbarkeits-Indikator
        if settings.llmProvider == .ollama {
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
    }

    private func fetchModels() async {
        guard isValidOllamaURL,
              let url = URL(string: "\(settings.ollamaBaseURL)/api/tags") else { return }
        loadingModels = true
        defer { loadingModels = false }
        do {
            let (data, _) = try await URLSession.shared.data(
                for: URLRequest(url: url, timeoutInterval: 4))
            let response = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            let names = response.models.map(\.name).sorted()
            availableModels = names
            if !names.isEmpty && !names.contains(settings.ollamaModel) {
                settings.ollamaModel = names[0]
            }
        } catch {
            availableModels = []
        }
    }

    private func checkOllama() async {
        ollamaReachable = nil
        guard let url = URL(string: settings.ollamaBaseURL) else { ollamaReachable = false; return }
        do {
            let (_, response) = try await URLSession.shared.data(
                for: URLRequest(url: url, timeoutInterval: 3))
            ollamaReachable = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            ollamaReachable = false
        }
    }
}

// MARK: – Ollama /api/tags Response

private struct OllamaTagsResponse: Decodable {
    struct Model: Decodable { let name: String }
    let models: [Model]
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

    private var isNew: Bool {
        draft.name.isEmpty && draft.prompt == AppSettings.defaultPrompt
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

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
                    Text(
                        "Schreibe hier, wie der Text umgeformt werden soll. Der Diktat-Text wird automatisch in <diktat>…</diktat>-Tags eingebettet.")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 520, height: 440)
    }
}
