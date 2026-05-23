import AppKit
import SwiftUI

/// Zeigt eine Tastenkombination als Badges und erlaubt das Aufzeichnen einer neuen.
struct ShortcutRecorderView: View {
    let label: String
    @Binding var shortcut: ShortcutConfig

    @State private var isRecording = false
    @State private var monitor: Any? = nil
    @State private var shake = false

    var body: some View {
        HStack(spacing: 10) {
            Text(label)

            Spacer()

            if isRecording {
                // Aufzeichnungs-Modus
                HStack(spacing: 6) {
                    Text("Taste drücken…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .italic()

                    Button("Abbrechen") { stopRecording(save: false) }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .transition(.opacity)
            } else {
                // Normal-Modus: Badges + Ändern-Button
                HStack(spacing: 3) {
                    ForEach(Array(shortcut.displayKeys.enumerated()), id: \.offset) { idx, key in
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
                .offset(x: shake ? -4 : 0)
                .animation(shake ? .interpolatingSpring(stiffness: 500, damping: 10) : .default,
                           value: shake)

                Button("Ändern") { startRecording() }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isRecording)
        .onDisappear { stopRecording(save: false) }
    }

    // MARK: – Aufzeichnung starten / stoppen

    private func startRecording() {
        isRecording = true
        // Lokaler Monitor – Settings-Fenster muss Key-Fenster sein
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [self] event in
            handleCapturedEvent(event)
            return nil   // Event konsumieren (nicht weiterleiten)
        }
    }

    private func stopRecording(save: Bool) {
        isRecording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    // MARK: – Event auswerten

    private func handleCapturedEvent(_ event: NSEvent) {
        // Escape = Abbrechen
        if event.type == .keyDown && event.keyCode == 53 {
            stopRecording(save: false)
            return
        }

        // Fn-Taste (flagsChanged, keyCode 63, function-Flag gesetzt)
        if event.type == .flagsChanged && event.keyCode == 63 && event.modifierFlags.contains(.function) {
            let mods = event.modifierFlags
                .intersection([.command, .option, .control, .shift])
            shortcut = ShortcutConfig(
                isFlagsBased: true,
                keyCode: 63,
                modifierRaw: mods.rawValue
            )
            stopRecording(save: true)
            return
        }

        // Normale Taste (keyDown) – mindestens ein Modifier nötig
        if event.type == .keyDown {
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard !mods.isEmpty else {
                // Kein Modifier → Schütteln als visuelles Feedback
                triggerShake()
                return
            }
            shortcut = ShortcutConfig(
                isFlagsBased: false,
                keyCode: event.keyCode,
                modifierRaw: mods.rawValue
            )
            stopRecording(save: true)
        }
    }

    private func triggerShake() {
        shake = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
    }
}
