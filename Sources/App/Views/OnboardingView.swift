import AppKit
import AVFoundation
import SwiftUI

// MARK: – Onboarding-Schritte

private enum OnboardingStep: Int, CaseIterable {
    case microphone = 0
    case accessibility = 1
    case done = 2

    var title: String {
        switch self {
        case .microphone:   return "Mikrofon"
        case .accessibility: return "Bedienungshilfen"
        case .done:          return "Bereit"
        }
    }
}

// MARK: – Haupt-View

struct OnboardingView: View {
    @State private var step: OnboardingStep = .microphone
    @State private var micGranted  = false
    @State private var axGranted   = false
    @State private var axPolling   = false
    @State private var axTimer: Timer? = nil

    // Callback wenn Onboarding abgeschlossen
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ───────────────────────────────────────────────────────
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                Text("Willkommen bei Dicto")
                    .font(.title2.bold())
            }
            .padding(.top, 36)
            .padding(.bottom, 24)

            // ── Step-Indicator ────────────────────────────────────────────────
            stepIndicator
                .padding(.bottom, 32)

            // ── Step-Inhalt ───────────────────────────────────────────────────
            Group {
                switch step {
                case .microphone:    microphoneStep
                case .accessibility: accessibilityStep
                case .done:          doneStep
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)

            Spacer(minLength: 32)
        }
        .frame(width: 460, height: 480)
        .background(.regularMaterial)
        .onDisappear { axTimer?.invalidate() }
    }

    // MARK: – Step-Indicator

    private var stepIndicator: some View {
        HStack(spacing: 0) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { s in
                // Kreis
                ZStack {
                    Circle()
                        .fill(circleColor(for: s))
                        .frame(width: 28, height: 28)
                    if isDone(s) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(s.rawValue + 1)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(s == step ? .white : .secondary)
                    }
                }

                // Verbindungslinie (außer nach letztem Schritt)
                if s != OnboardingStep.allCases.last {
                    Rectangle()
                        .fill(s.rawValue < step.rawValue ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 56)
        .animation(.spring(response: 0.35), value: step)
    }

    private func circleColor(for s: OnboardingStep) -> Color {
        if isDone(s) { return .accentColor }
        if s == step { return .accentColor }
        return Color.secondary.opacity(0.2)
    }

    private func isDone(_ s: OnboardingStep) -> Bool {
        s.rawValue < step.rawValue
    }

    // MARK: – Schritt 1: Mikrofon

    private var microphoneStep: some View {
        VStack(spacing: 20) {
            permissionIcon(
                systemName: "mic.fill",
                color: .red,
                granted: micGranted
            )

            VStack(spacing: 8) {
                Text("Mikrofon-Zugriff")
                    .font(.headline)
                Text("Dicto nimmt deine Sprache auf und wandelt sie lokal in Text um. Deine Aufnahmen verlassen nie das Gerät.")
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
            // Bereits erteilt? Direkt als granted zeigen
            micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        }
    }

    // MARK: – Schritt 2: Bedienungshilfen

    private var accessibilityStep: some View {
        VStack(spacing: 20) {
            permissionIcon(
                systemName: "hand.point.up.left.fill",
                color: .blue,
                granted: axGranted
            )

            VStack(spacing: 8) {
                Text("Bedienungshilfen-Zugriff")
                    .font(.headline)
                Text("Damit Dicto Text direkt an der Cursor-Position einfügen kann, benötigt es Zugriff auf die Bedienungshilfen.\n\nKlicke auf 'Einstellungen öffnen' und aktiviere Dicto in der Liste.")
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
                    Button("Einstellungen öffnen") {
                        // AXIsProcessTrustedWithOptions öffnet den System-Dialog
                        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        _ = AXIsProcessTrustedWithOptions(opts)
                        startAxPolling()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if axPolling {
                        HStack(spacing: 6) {
                            ProgressView().scaleEffect(0.7)
                            Text("Warte auf Freigabe…")
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
            if axGranted { /* bereits erteilt, kein Polling nötig */ }
        }
    }

    private func startAxPolling() {
        guard !axPolling else { return }
        axPolling = true
        axTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if AXIsProcessTrusted() {
                axTimer?.invalidate()
                axTimer = nil
                withAnimation { axGranted = true; axPolling = false }
            }
        }
    }

    // MARK: – Schritt 3: Fertig

    private var doneStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 44))
                .foregroundStyle(.yellow)
                .symbolEffect(.bounce, value: step)

            VStack(spacing: 8) {
                Text("Dicto ist bereit!")
                    .font(.headline)
                Text("Drücke die Tastenkürzel um loszulegen.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            // Shortcut-Übersicht
            VStack(spacing: 8) {
                shortcutRow(keys: ["Fn"],       label: "Diktieren starten / stoppen",   icon: "mic.fill")
                shortcutRow(keys: ["⌥", "Fn"], label: "Text transformieren",            icon: "wand.and.sparkles")
                shortcutRow(keys: ["⌘", "↩"],  label: "Text einfügen",                  icon: "return")
            }
            .padding(.vertical, 4)

            Button("Loslegen") { onComplete() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    // MARK: – Hilfsfunktionen

    private func advance() {
        let next = step.rawValue + 1
        if let nextStep = OnboardingStep(rawValue: next) {
            withAnimation(.spring(response: 0.35)) { step = nextStep }
        }
    }

    @ViewBuilder
    private func permissionIcon(systemName: String, color: Color, granted: Bool) -> some View {
        ZStack {
            Circle()
                .fill(granted ? Color.green.opacity(0.15) : color.opacity(0.12))
                .frame(width: 72, height: 72)
            Image(systemName: systemName)
                .font(.system(size: 28))
                .foregroundStyle(granted ? .green : color)
        }
    }

    private func shortcutRow(keys: [String], label: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            HStack(spacing: 3) {
                ForEach(Array(keys.enumerated()), id: \.offset) { idx, key in
                    if idx > 0 {
                        Text("+")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Text(key)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Text(label)
                .font(.callout)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}
