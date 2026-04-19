import AppKit

final class HotkeyService {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private(set) var isAvailable = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isFnDown = false

    // NX_SECONDARYFNMASK – undokumentiertes Flag für Fn/Globe-Taste
    private static let fnKeyFlag = CGEventFlags(rawValue: 0x800000)

    init() {
        // Accessibility-Dialog zeigen falls noch nicht erteilt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        tryInstallTap()
    }

    // Aufrufbar nachdem Nutzer Berechtigung in Systemeinstellungen erteilt hat –
    // kein App-Neustart nötig.
    func retryIfNeeded() {
        guard !isAvailable else { return }
        tryInstallTap()
    }

    private func tryInstallTap() {
        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else { return }

        // Alten Tap abbauen falls ein Retry stattfindet
        tearDownTap()

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isAvailable = true
    }

    private func tearDownTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        eventTap = nil
        runLoopSource = nil
    }

    fileprivate func handleEvent(_ event: CGEvent) {
        let fnCurrentlyDown = event.flags.contains(Self.fnKeyFlag)
        guard fnCurrentlyDown != isFnDown else { return }
        isFnDown = fnCurrentlyDown
        if fnCurrentlyDown { onKeyDown?() } else { onKeyUp?() }
    }

    deinit { tearDownTap() }
}

private let hotkeyEventTapCallback: CGEventTapCallBack = { _, _, event, refcon in
    guard let refcon else { return Unmanaged.passUnretained(event) }
    Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue().handleEvent(event)
    return Unmanaged.passUnretained(event)
}
