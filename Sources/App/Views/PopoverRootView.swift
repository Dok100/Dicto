import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject var appState: AppState
    @State private var editableText = ""
    @State private var showHistory = false

    /// Treibt die State-Transition-Animation: SwiftUI erkennt durch die neue ID,
    /// dass der Inhalt neu gerendert werden soll, und wendet .transition() an.
    private var stateTag: String {
        if appState.isTransformRecording { return "transform-recording" }
        if appState.isRecording { return "recording" }
        switch appState.transcriptionState {
        case .idle: return "idle"
        case .loadingModel: return "loading"
        case .transcribing: return "transcribing"
        case .streaming: return "streaming"
        case .done: return "done"
        case .error: return "error"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider().opacity(0.4)

            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            previewActionsSection

            Divider().opacity(0.4)

            stylePicker
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

            Divider().opacity(0.4)

            footerBar
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
        }
        .frame(minWidth: 380, minHeight: 300)
        .background(.regularMaterial)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: stateTag)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showHistory)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: showPreviewActions)
        .onChange(of: appState.transcriptionState) { state in
            switch state {
            case .done, .streaming: showHistory = false
            default: break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dictoCmdReturn)) { _ in
            guard case .done(let text) = appState.transcriptionState else { return }
            if appState.isTransformResult {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(editableText, forType: .string)
                appState.historyService.add(text: editableText)
                appState.dismissResult()
            } else {
                Task { await appState.confirmPaste(original: text, edited: editableText) }
            }
        }
    }

    // MARK: – Header

    private var headerView: some View {
        HStack(spacing: 10) {
            ZStack {
                // Pulsierender Hintergrundkreis bei Aufnahme
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                    .scaleEffect(appState.isRecording ? 1.18 : 1.0)
                    .animation(
                        appState.isRecording
                            ? .easeInOut(duration: 0.65).repeatForever(autoreverses: true)
                            : .spring(response: 0.3),
                        value: appState.isRecording)

                Image(systemName: iconName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(iconColor)
                    .animation(.easeInOut(duration: 0.15), value: appState.isRecording)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Dicto")
                    .font(.system(size: 13, weight: .semibold))
                Text(statusLabel)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: statusLabel)
            }

            Spacer()
        }
    }

    private var iconName: String {
        if appState.isTransformRecording { return "wand.and.sparkles" }
        return appState.isRecording ? "mic.fill" : "mic"
    }

    private var iconColor: Color {
        if appState.isTransformRecording { return .purple }
        if appState.isRecording { return .red }
        switch appState.transcriptionState {
        case .error: return .red
        default: return .accentColor
        }
    }

    private var statusLabel: String {
        if appState.isTransformRecording { return "Transform läuft …" }
        if appState.isRecording { return "Aufnahme läuft …" }
        switch appState.transcriptionState {
        case .idle: return "Bereit"
        case .loadingModel: return "Modell wird geladen …"
        case .transcribing: return "Transkribiere …"
        case .streaming: return "KI schreibt …"
        case .done: return "Fertig"
        case .error: return "Fehler"
        }
    }

    // MARK: – Preview-Aktionen sichtbar?

    private var showPreviewActions: Bool {
        guard case .done = appState.transcriptionState else { return false }
        return appState.settings.previewEnabled || appState.isTransformResult
    }

    // MARK: – Footer

    private var footerBar: some View {
        HStack(spacing: 2) {
            footerButton(icon: "gearshape", help: "Einstellungen") {
                appState.onOpenSettings?()
            }
            footerButton(icon: showHistory ? "clock.fill" : "clock", help: "Verlauf") {
                withAnimation { showHistory.toggle() }
            }
            footerButton(icon: "questionmark.circle", help: "Hilfe") {
                appState.onOpenHelp?()
            }
            Spacer()
            footerButton(icon: "power", help: "Beenden ⌘Q") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    private func footerButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
    }

    // MARK: – Preview-Aktionsbuttons

    @ViewBuilder
    private var previewActions: some View {
        if case .done(let text) = appState.transcriptionState,
           appState.settings.previewEnabled || appState.isTransformResult
        {
            VStack(spacing: 6) {
                if appState.isTransformResult {
                    HStack(spacing: 8) {
                        Button("Kopieren") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(editableText, forType: .string)
                            appState.historyService.add(text: editableText)
                            appState.dismissResult()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        Button("Einfügen") {
                            Task { await appState.confirmPaste(original: text, edited: editableText) }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!appState.isAccessibilityAuthorized)
                    }
                } else {
                    Button("⌘↩  Einfügen") {
                        Task { await appState.confirmPaste(original: text, edited: editableText) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!appState.isAccessibilityAuthorized)
                }

                if !appState.isAccessibilityAuthorized {
                    PermissionHint(
                        message: "Eingabehilfen fehlt – Text nicht eingefügt.",
                        settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
                        appState: appState)
                }
            }
        }
    }

    // MARK: – Verlauf

    @State private var showClearConfirm = false

    @ViewBuilder
    private var historyView: some View {
        let entries = appState.historyService.entries
        if entries.isEmpty {
            ContentUnavailableView("Noch kein Verlauf", systemImage: "clock")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 6) {
                HStack {
                    Text("Verlauf")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showClearConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Verlauf löschen")
                    .confirmationDialog(
                        "Verlauf löschen?",
                        isPresented: $showClearConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Löschen", role: .destructive) {
                            appState.historyService.clear()
                        }
                        Button("Abbrechen", role: .cancel) {}
                    } message: {
                        Text("Alle Einträge werden unwiderruflich gelöscht.")
                    }
                }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.date, formatter: Self.relativeDateFormatter)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(entry.text)
                                    .font(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 1)
                }
                .frame(minHeight: 80, maxHeight: 200)
            }
        }
    }

    private static let relativeDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "de_DE")
        f.doesRelativeDateFormatting = true
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    // MARK: – Status-Area (Berechtigungen)

    @ViewBuilder
    private var statusArea: some View {
        switch appState.missingPermission {
        case .inputMonitoring:
            PermissionHint(
                message: "Eingabe-Überwachung fehlt.",
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent",
                appState: appState)
        case .microphone:
            PermissionHint(
                message: "Mikrofon-Zugriff fehlt.",
                settingsURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone",
                appState: appState)
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
                RecordingRingsView(isTransform: appState.isTransformRecording)
            } else {
                idleView
            }

        case .loadingModel(let progress):
            VStack(spacing: 8) {
                if progress > 0 {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                    Text("Modell wird geladen … \(Int(progress * 100)) %")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                    Text("Modell wird geladen …")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .transcribing:
            TranscribingDotsView()

        case .streaming(let text):
            StreamingTextView(text: text)

        case .done(let text):
            if appState.settings.previewEnabled || appState.isTransformResult {
                TextEditor(text: $editableText)
                    .font(.body)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
                    .onAppear { editableText = text }
                    .onChange(of: text) { editableText = $1 }
            } else {
                ScrollView {
                    Text(text)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .onAppear { editableText = text }
                .onChange(of: text) { editableText = $1 }
            }

        case .error(let error):
            errorView(error: error)
        }
    }

    // MARK: – Fehler-Ansicht

    private func errorView(error: DictoError) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundStyle(.red)

            Text(error.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)

            Text(error.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Aktions-Buttons: Einstellungen öffnen wenn sinnvoll
            VStack(spacing: 6) {
                if error.needsAppSettings {
                    Button("KI-Einstellungen öffnen") {
                        appState.onOpenSettings?()
                        appState.dismissError()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if let url = error.systemSettingsURL {
                    Button("Systemeinstellungen öffnen") {
                        NSWorkspace.shared.open(url)
                        appState.dismissError()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Button("Schließen") {
                    appState.dismissError()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Idle-Ansicht

    private var idleView: some View {
        VStack(alignment: .leading, spacing: 12) {
            shortcutRow(keys: ["Fn"], description: "Diktieren", icon: "mic.fill")
            transformRow
            Divider().padding(.vertical, 2)
            // ⌘↩ funktioniert nur im Preview-Modus (Panel muss offen sein)
            if appState.settings.previewEnabled {
                shortcutRow(keys: ["⌘", "↩"], description: "Einfügen", icon: "return")
            }
            shortcutRow(keys: ["⎋"], description: "Schließen", icon: "xmark")
            shortcutRow(keys: ["⌘", "Q"], description: "Beenden", icon: "xmark.circle")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var transformRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            shortcutRow(keys: ["⌥", "Fn"], description: "Transform", icon: "wand.and.sparkles")
            HStack(spacing: 6) {
                // Einrückung passend zum Icon + Abstand der shortcutRow
                Color.clear.frame(width: 20 + 10, height: 1)
                Text("Text markieren → Shortcut halten → Befehl sprechen")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
    }

    private func shortcutRow(keys: [String], description: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 20, alignment: .center)

            Text(description)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            // Jede Taste als eigenes Badge, mit + dazwischen
            HStack(spacing: 4) {
                ForEach(Array(keys.enumerated()), id: \.offset) { i, key in
                    if i > 0 {
                        Text("+")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(.tertiary)
                    }
                    Text(key)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: – Haupt-Inhaltsbereich (Status oder Verlauf)

    @ViewBuilder
    private var mainContent: some View {
        if showHistory {
            historyView
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        } else {
            statusArea
                .id(stateTag)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .center)))
        }
    }

    // MARK: – Preview-Aktionen (optional)

    @ViewBuilder
    private var previewActionsSection: some View {
        if showPreviewActions {
            Divider().opacity(0.4)
            previewActions
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: – Stil-Picker (feste + eigene Stile)

    private var stylePicker: some View {
        VStack(spacing: 6) {
            Picker("Stil", selection: Binding(
                get: { appState.dictationStyle },
                set: { appState.selectFixedStyle($0) }))
            {
                ForEach(DictationStyle.allCases, id: \.self) { style in
                    Text(style.label).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(appState.isRecording)

            if !appState.settings.customStyles.isEmpty {
                customStylesRow
            }

            if appState.dictationStyle == .translate
                && appState.selectedCustomStyle == nil
                && !appState.settings.llmEnabled
            {
                ollamaWarning("KI muss aktiviert sein für die Übersetzung.")
            }
            if appState.selectedCustomStyle != nil && !appState.settings.llmEnabled {
                ollamaWarning("KI muss aktiviert sein für eigene Stile.")
            }
        }
        .animation(.spring(response: 0.25), value: appState.settings.customStyles.count)
        .animation(.spring(response: 0.25), value: appState.selectedCustomStyle?.id)
    }

    private var customStylesRow: some View {
        VStack(spacing: 4) {
            Divider().opacity(0.3)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(appState.settings.customStyles) { style in
                        Button(style.name) { appState.selectCustomStyle(style) }
                            .buttonStyle(CustomStyleChipStyle(
                                isSelected: appState.selectedCustomStyle?.id == style.id))
                            .disabled(appState.isRecording)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func ollamaWarning(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(.orange)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
    }
}

// MARK: – Level B: Pulsierende Aufnahme-Ringe

private struct RecordingRingsView: View {
    let isTransform: Bool
    @State private var animate = false

    private var color: Color {
        isTransform ? .purple : .red
    }

    private var icon: String {
        isTransform ? "wand.and.sparkles" : "mic.fill"
    }

    private var label: String {
        isTransform ? "Transform-Aufnahme läuft …" : "Aufnahme läuft …"
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // 3 Ringe, jeweils mit Versatz starten – erzeugt Ripple-Effekt
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(color.opacity(animate ? 0 : 0.45), lineWidth: 1.5)
                        .scaleEffect(animate ? 3.2 : 1.0)
                        .animation(
                            .easeOut(duration: 1.6)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.52),
                            value: animate)
                }
                // Gefüllter Hintergrundkreis
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 68, height: 68)
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(color)
            }
            .frame(width: 90, height: 90)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(color.opacity(0.85))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Minimaler Delay damit SwiftUI den initialen Zustand rendert
            // bevor die Animation startet – verhindert Sprung bei .id()-Wechsel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animate = true
            }
        }
        .onDisappear { animate = false }
    }
}

// MARK: – Level B: Hüpfende Punkte beim Transkribieren

private struct TranscribingDotsView: View {
    @State private var animate = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.secondary.opacity(0.65))
                        .frame(width: 9, height: 9)
                        .scaleEffect(animate ? 1.0 : 0.4)
                        .opacity(animate ? 1.0 : 0.25)
                        .animation(
                            .easeInOut(duration: 0.42)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.14),
                            value: animate)
                }
            }
            Text("Transkribiere …")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                animate = true
            }
        }
        .onDisappear { animate = false }
    }
}

// MARK: – Streaming-Textanzeige

private struct StreamingTextView: View {
    let text: String
    @State private var showCursor = true
    @State private var dotPhase = 0

    var body: some View {
        Group {
            if text.isEmpty {
                // Warte auf ersten Token → pulsierende Punkte
                waitingView
            } else {
                // Text läuft ein
                scrollingText
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.15)) { showCursor.toggle() }
            }
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                dotPhase = (dotPhase + 1) % 4
            }
        }
    }

    /// Drei pulsierende Punkte + Label während Ollama den ersten Token berechnet
    private var waitingView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 9) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.accentColor.opacity(dotPhase == i ? 0.9 : 0.25))
                        .frame(width: 9, height: 9)
                        .scaleEffect(dotPhase == i ? 1.2 : 0.85)
                        .animation(.easeInOut(duration: 0.3), value: dotPhase)
                }
            }
            Text("Warte auf Antwort …")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var scrollingText: some View {
        ScrollViewReader { proxy in
            ScrollView {
                (Text(text) + Text(showCursor ? "▍" : " ")
                    .foregroundColor(.accentColor))
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id("streamBottom")
                    .padding(.bottom, 2)
            }
            .onChange(of: text) { _ in
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("streamBottom", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: – Berechtigungs-Hinweis

private struct PermissionHint: View {
    let message: String
    let settingsURL: String
    let appState: AppState

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 24))
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                Button("Einstellungen öffnen") {
                    if let url = URL(string: settingsURL) { NSWorkspace.shared.open(url) }
                }
                .font(.caption)
                Button("Neu prüfen") { appState.recheckPermissions() }
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: – Custom-Stil-Chip-ButtonStyle

struct CustomStyleChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isSelected)
    }
}
