import AppKit

final class HotkeyService {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?
    var onTransformKeyDown: (() -> Void)?
    var onTransformKeyUp: (() -> Void)?

    private(set) var isAvailable = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isFnDown = false
    private var isTransformMode = false

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
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleEvent(event)
        }
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

        if fnCurrentlyDown {
            // Alt (Option) bereits gehalten → Transform-Modus
            isTransformMode = event.modifierFlags.contains(.option)
            if isTransformMode {
                onTransformKeyDown?()
            } else {
                onKeyDown?()
            }
        } else {
            if isTransformMode {
                onTransformKeyUp?()
            } else {
                onKeyUp?()
            }
            isTransformMode = false
        }
    }

    deinit {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
    }
}
