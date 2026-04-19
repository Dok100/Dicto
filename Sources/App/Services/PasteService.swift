import AppKit
import CoreGraphics

final class PasteService {
    private static let vKeyCode: CGKeyCode = 0x09  // kVK_ANSI_V

    var isAccessibilityAuthorized: Bool {
        AXIsProcessTrusted()
    }

    // Zeigt den macOS-System-Dialog "Dicto möchte Ihren Computer steuern"
    // und trägt die App korrekt in Eingabehilfen ein.
    func requestAccessibilityIfNeeded() {
        guard !isAccessibilityAuthorized else { return }
        let key = kAXTrustedCheckOptionPrompt.takeRetainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func paste(text: String) {
        let pasteboard = NSPasteboard.general
        let savedString = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        guard isAccessibilityAuthorized else { return }

        let src = CGEventSource(stateID: .hidSystemState)

        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: Self.vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)

        let keyUp = CGEvent(keyboardEventSource: src, virtualKey: Self.vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)

        // Clipboard nach der Verarbeitung des Paste-Events wiederherstellen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            pasteboard.clearContents()
            if let old = savedString {
                pasteboard.setString(old, forType: .string)
            }
        }
    }
}
