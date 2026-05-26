import AppKit
import AVFoundation
import SwiftUI

// MARK: – Onboarding-Schritte

private enum OnboardingStep: Int, CaseIterable {
    case microphone = 0
    case accessibility = 1
    case transcriptionEngine = 2
    case aiSetup = 3
    case done = 4
}

// MARK: – Haupt-View

struct OnboardingView: View {
    @ObservedObject var settings: AppSettings
    @State private var step: OnboardingStep = .microphone

    /// Schritt 1
    @State private var micGranted = false
    // Schritt 2
    @State private var axGranted = false
    @State private var axPolling = false
    @State private var axTimer: Timer? = nil
    // Schritt 4
    @State private var openAIApiKeyDraft = ""
    @State private var showApiKey = false
    @State private var selectedAIOption: AIOption = .none

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────────────────
            VStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                Text("Willkommen bei Dicto")
                    .font(.title2.bold())
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // ── Step-Indicator ────────────────────────────────────────────────
            stepIndicator
                .padding(.bottom, 24)

            // ── Schritt-Inhalt ────────────────────────────────────────────────
            Group {
                switch step {
                case .microphone: microphoneStep
                case .accessibility: accessibilityStep
                case .transcriptionEngine: engineStep
                case .aiSetup: aiStep
                case .done: doneStep
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 36)

            Spacer(minLength: 24)
        }
        .frame(width: 480, height: 560)
        .background(.regularMaterial)
        .onDisappear { axTimer?.invalidate() }
    }

    // MARK: – Step-Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                ZStack {
                    Circle()
                        .fill(circleColor(for: s))
                        .frame(width: 24, height: 24)
                    if isDone(s) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(s.rawValue + 1)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(s == step ? .white : .secondary)
                    }
                }
                if s != OnboardingStep.allCases.last {
                    Rectangle()
                        .fill(s.rawValue < step.rawValue ? Color.accentColor : Color.secondary.opacity(0.25))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 48)
        .animation(.spring(response: 0.35), value: step)
    }

    private func circleColor(for s: OnboardingStep) -> Color {
        if isDone(s) || s == step { return .accentColor }
        return Color.secondary.opacity(0.2)
    }

    private func isDone(_ s: OnboardingStep) -> Bool {
        s.rawValue < step.rawValue
    }

    // MARK: – Schritt 1: Mikrofon

    private var microphoneStep: some View {
        VStack(spacing: 18) {
            permissionIcon(systemName: "mic.fill", color: .red, granted: micGranted)

            VStack(spacing: 6) {
                Text("Mikrofon-Zugriff")
                    .font(.headline)
                Text(
                    "Dicto nimmt deine Sprache auf und wandelt sie lokal in Text um. Deine Aufnahmen verlassen nie das Gerät.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if micGranted {
                Label("Mikrofon freigegeben", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout.bold())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                Button("Weiter") { advance() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            } else {
                Button("Zugriff erlauben") {
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        DispatchQueue.main.async {
                            withAnimation { micGranted = granted }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .animation(.spring(response: 0.3), value: micGranted)
        .onAppear {
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
    }

    // MARK: – Schritt 2: Bedienungshilfen

    private var accessibilityStep: some View {
        VStack(spacing: 18) {
            permissionIcon(systemName: "hand.point.up.left.fill", color: .blue, granted: axGranted)

            VStack(spacing: 6) {
                Text("Bedienungshilfen-Zugriff")
                    .font(.headline)
                Text(
                    "Damit Dicto Text direkt an der Cursor-Position einfuegen kann, benoetigt es Zugriff auf die Bedienungshilfen.\n\nKlicke auf 'Einstellungen oeffnen' und aktiviere Dicto in der Liste.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if axGranted {
                Label("Bedienungshilfen freigegeben", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.callout.bold())
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                Button("Weiter") { advance() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            } else {
                VStack(spacing: 10) {
                    Button("Einstellungen oeffnen") {
                        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        _ = AXIsProcessTrustedWithOptions(opts)
                        startAxPolling()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if axPolling {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("Warte auf Freigabe...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3), value: axGranted)
        .onAppear {
            axGranted = AXIsProcessTrusted()
        }
    }

    private func startAxPolling() {
        guard !axPolling else { return }
        axPolling = true
        axTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if AXIsProcessTrusted() {
                axTimer?.invalidate(); axTimer = nil
                withAnimation { axGranted = true; axPolling = false }
            }
        }
    }

    // MARK: – Schritt 3: Spracherkennung

    private var engineStep: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Spracherkennung")
                    .font(.headline)
                Text("Womit soll Dicto deine Sprache erkennen?")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                EngineCard(
                    isSelected: settings.transcriptionEngine == .apple,
                    icon: "apple.logo",
                    iconColor: .primary,
                    title: "Apple (live, kein Download)",
                    subtitle: "Text erscheint live waehrend der Aufnahme. Sofort verfuegbar.")
                {
                    settings.transcriptionEngine = .apple
                }

                EngineCard(
                    isSelected: settings.transcriptionEngine == .whisper,
                    icon: "waveform",
                    iconColor: .blue,
                    title: "Whisper (praeziser, offline)",
                    subtitle: "Sehr hohe Genauigkeit, Fachvokabular, Umlaute. Einmaliger Download ~800 MB.")
                {
                    settings.transcriptionEngine = .whisper
                }
            }

            Text("Du kannst dies jederzeit unter Einstellungen -> Allgemein aendern.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Button("Weiter") { advance() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    // MARK: – Schritt 4: KI-Textglaettung

    private enum AIOption { case ollama, openAI, none }

    private var aiStep: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text("KI-Textglaettung")
                    .font(.headline)
                Text("Dicto kann deinen Diktat-Text automatisch glaetten und umformulieren.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                AIOptionCard(
                    isSelected: selectedAIOption == .ollama,
                    icon: "desktopcomputer",
                    iconColor: .green,
                    title: "Ollama (lokal)",
                    subtitle: "Kostenlos, laeuft auf deinem Mac. Erfordert Ollama + Modell (z.B. qwen2.5:32b).")
                {
                    selectedAIOption = .ollama
                    settings.llmProvider = .ollama
                }

                AIOptionCard(
                    isSelected: selectedAIOption == .openAI,
                    icon: "cloud.fill",
                    iconColor: .blue,
                    title: "OpenAI API",
                    subtitle: "Sehr schnell, geringe Kosten. API-Key erforderlich (platform.openai.com).")
                {
                    selectedAIOption = .openAI
                    settings.llmProvider = .openAI
                }

                // API-Key Feld erscheint wenn OpenAI gewaehlt
                if selectedAIOption == .openAI {
                    HStack(spacing: 6) {
                        if showApiKey {
                            TextField("sk-...", text: $openAIApiKeyDraft)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("API-Key eingeben (sk-...)", text: $openAIApiKeyDraft)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button { showApiKey.toggle() } label: {
                            Image(systemName: showApiKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                AIOptionCard(
                    isSelected: selectedAIOption == .none,
                    icon: "xmark.circle",
                    iconColor: .secondary,
                    title: "Ohne KI",
                    subtitle: "Rohtext wird direkt eingefuegt. KI kann spaeter in den Einstellungen aktiviert werden.")
                {
                    selectedAIOption = .none
                    settings.llmProvider = .disabled
                }
            }

            Button("Weiter") {
                // API-Key speichern wenn OpenAI gewaehlt
                if selectedAIOption == .openAI && !openAIApiKeyDraft.isEmpty {
                    settings.openAIApiKey = openAIApiKeyDraft
                }
                advance()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selectedAIOption == .openAI && openAIApiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty)
        }
        .animation(.spring(response: 0.3), value: selectedAIOption == .openAI)
        .onAppear {
            // Vorauswahl basierend auf bestehenden Einstellungen
            switch settings.llmProvider {
            case .disabled: selectedAIOption = .none
            case .ollama: selectedAIOption = .ollama
            case .openAI: selectedAIOption = .openAI
            }
            openAIApiKeyDraft = settings.openAIApiKey
        }
    }

    // MARK: – Schritt 5: Fertig

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce, value: step)

            VStack(spacing: 6) {
                Text("Dicto ist bereit!")
                    .font(.headline)
                Text("Hier ein kurzer Ueberblick ueber alle Funktionen.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // Feature-Uebersicht
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                FeatureTile(
                    icon: "mic.fill",
                    color: .red,
                    title: "Diktat",
                    desc: "Fn halten, sprechen, loslegen")
                FeatureTile(
                    icon: "paintpalette.fill",
                    color: .pink,
                    title: "Stile",
                    desc: "Neutral, Formell, Locker, Empathisch, EN")
                FeatureTile(
                    icon: "wand.and.sparkles",
                    color: .indigo,
                    title: "Transform",
                    desc: "Text markieren + Sprachbefehl")
                FeatureTile(
                    icon: "eye.fill",
                    color: .blue,
                    title: "Preview",
                    desc: "Text pruefen bevor er eingefuegt wird")
            }

            Button("Loslegen") { onComplete() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Text("Alle Funktionen erklaert: Panel -> ?")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: – Hilfsfunktionen

    private func advance() {
        let next = step.rawValue + 1
        if let nextStep = OnboardingStep(rawValue: next) {
            withAnimation(.spring(response: 0.35)) { step = nextStep }
        }
    }

    private func permissionIcon(systemName: String, color: Color, granted: Bool) -> some View {
        ZStack {
            Circle()
                .fill(granted ? Color.green.opacity(0.15) : color.opacity(0.12))
                .frame(width: 68, height: 68)
            Image(systemName: systemName)
                .font(.system(size: 26))
                .foregroundStyle(granted ? .green : color)
        }
    }
}

// MARK: – Engine-Auswahl-Karte

private struct EngineCard: View {
    let isSelected: Bool
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
                    .font(.system(size: 18))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.06))
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: – KI-Option-Karte

private struct AIOptionCard: View {
    let isSelected: Bool
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
                    .font(.system(size: 16))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.secondary.opacity(0.06))
                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: – Feature-Kachel

private struct FeatureTile: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 8))
    }
}
