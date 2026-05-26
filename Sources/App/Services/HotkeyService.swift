import AppKit

final class HotkeyService {
    // MARK: – Callbacks

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?
    var onTransformKeyDown: (() -> Void)?
    var onTransformKeyUp: (() -> Void)?

    private(set) var isAvailable = false

    // MARK: – Konfiguration

    var dictationShortcut: ShortcutConfig {
        didSet { reinstallMonitors() }
    }

    var transformShortcut: ShortcutConfig {
        didSet { reinstallMonitors() }
    }

    // MARK: – Interna

    private var flagsMonitorGlobal: Any?
    private var flagsMonitorLocal: Any?
    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?

    private enum ActiveMode { case none, dictation, transform }
    private var activeMode: ActiveMode = .none

    // MARK: – Init

    init(
        dictation: ShortcutConfig = .defaultDictation,
        transform: ShortcutConfig = .defaultTransform)
    {
        self.dictationShortcut = dictation
        self.transformShortcut = transform
        tryInstallMonitor()
    }

    func retryIfNeeded() {
        guard !isAvailable else { return }
        tryInstallMonitor()
    }

    // MARK: – Monitor-Installation

    private func tryInstallMonitor() {
        removeAllMonitors()

        // flagsChanged – immer aktiv (Fn-Taste + Modifier-only-Shortcuts)
        flagsMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
            self?.handleFlagsChanged(e)
        }
        flagsMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] e in
            self?.handleFlagsChanged(e)
            return e
        }

        // keyDown/keyUp – für normale Tastenkombinationen
        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] e in
            self?.handleKeyDown(e)
        }
        keyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] e in
            self?.handleKeyUp(e)
        }

        isAvailable = flagsMonitorGlobal != nil
    }

    private func reinstallMonitors() {
        activeMode = .none
        tryInstallMonitor()
    }

    private func removeAllMonitors() {
        for m in [flagsMonitorGlobal, flagsMonitorLocal, keyDownMonitor, keyUpMonitor] {
            if let m { NSEvent.removeMonitor(m) }
        }
        flagsMonitorGlobal = nil
        flagsMonitorLocal = nil
        keyDownMonitor = nil
        keyUpMonitor = nil
    }

    // MARK: – flagsChanged (Fn-Taste)

    private func handleFlagsChanged(_ event: NSEvent) {
        // Nur Fn-basierte Shortcuts hier behandeln
        guard event.keyCode == 63 else { return }

        let fnNowDown = event.modifierFlags.contains(.function)

        if fnNowDown && activeMode == .none {
            // Transform zuerst prüfen (spezifischer als Diktat)
            if transformShortcut.isFlagsBased && fnModifiersMatch(event: event, config: transformShortcut) {
                activeMode = .transform
                onTransformKeyDown?()
            } else if dictationShortcut.isFlagsBased && fnModifiersMatch(event: event, config: dictationShortcut) {
                activeMode = .dictation
                onKeyDown?()
            }
        } else if !fnNowDown {
            switch activeMode {
            case .transform: activeMode = .none; onTransformKeyUp?()
            case .dictation: activeMode = .none; onKeyUp?()
            case .none: break
            }
        }
    }

    private func fnModifiersMatch(event: NSEvent, config: ShortcutConfig) -> Bool {
        let want = config.modifierFlags // Nur die vom Nutzer konfigurierten Modifier
        let have = event.modifierFlags.intersection([.command, .option, .control, .shift])
        return want == have
    }

    // MARK: – keyDown / keyUp (normale Tasten)

    private func handleKeyDown(_ event: NSEvent) {
        guard activeMode == .none else { return }
        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])

        // Transform zuerst (spezifischer)
        if !transformShortcut.isFlagsBased,
           event.keyCode == transformShortcut.keyCode,
           mods == transformShortcut.modifierFlags
        {
            activeMode = .transform
            onTransformKeyDown?()
        } else if !dictationShortcut.isFlagsBased,
                  event.keyCode == dictationShortcut.keyCode,
                  mods == dictationShortcut.modifierFlags
        {
            activeMode = .dictation
            onKeyDown?()
        }
    }

    private func handleKeyUp(_ event: NSEvent) {
        switch activeMode {
        case .transform:
            if !transformShortcut.isFlagsBased, event.keyCode == transformShortcut.keyCode {
                activeMode = .none
                onTransformKeyUp?()
            }
        case .dictation:
            if !dictationShortcut.isFlagsBased, event.keyCode == dictationShortcut.keyCode {
                activeMode = .none
                onKeyUp?()
            }
        case .none:
            break
        }
    }

    deinit { removeAllMonitors() }
}
