import AppKit

final class HotkeyService {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private(set) var isAvailable = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isFnDown = false

    // Globe/Fn-Taste: keyCode 63, modifierFlags enthält .function wenn gedrückt.
    // Voraussetzung: Systemeinstellungen → Tastatur → 🌐-Taste → "Keine Aktion"
    private static let fnKeyCode: UInt16 = 63

    var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    init() {
        tryInstallMonitor()
    }

    func retryIfNeeded() {
        guard !isAvailable else { return }
        tryInstallMonitor()
    }

    private func tryInstallMonitor() {
        // NSEvent.addGlobalMonitorForEvents arbeitet auf Cocoa-Ebene und
        // empfängt Globe/Fn-Events zuverlässiger als CGEventTap
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleEvent(event)
        }
        // Local monitor damit das Popover den Hotkey auch empfängt wenn es im Fokus ist
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
        isAvailable = globalMonitor != nil
    }

    private func handleEvent(_ event: NSEvent) {
        guard event.keyCode == Self.fnKeyCode else { return }
        let fnCurrentlyDown = event.modifierFlags.contains(.function)
        guard fnCurrentlyDown != isFnDown else { return }
        isFnDown = fnCurrentlyDown
        if fnCurrentlyDown { onKeyDown?() } else { onKeyUp?() }
    }

    deinit {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
    }
}
