import AppKit

final class HotkeyService {
    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private(set) var isAvailable = false
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isFnDown = false

    // NX_SECONDARYFNMASK – nicht offiziell dokumentiertes Flag für die Fn/Globe-Taste.
    // Plan B: keyCode 0x3E (rechte Ctrl) als Alternative in PROJ-7 konfigurierbar.
    private static let fnKeyFlag = CGEventFlags(rawValue: 0x800000)

    init() {
        setup()
    }

    private func setup() {
        // Zeigt Accessibility-Berechtigungsdialog beim ersten Start
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        let mask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: hotkeyEventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )

        isAvailable = eventTap != nil
        guard let tap = eventTap else { return }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    // Wird vom C-Callback aufgerufen, läuft auf dem Main Thread (Main RunLoop)
    fileprivate func handleEvent(_ event: CGEvent) {
        let fnCurrentlyDown = event.flags.contains(Self.fnKeyFlag)
        guard fnCurrentlyDown != isFnDown else { return }
        isFnDown = fnCurrentlyDown

        if fnCurrentlyDown {
            onKeyDown?()
        } else {
            onKeyUp?()
        }
    }

    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }
}

// C-kompatibler Callback – darf keine Swift-Werte clos-over, nutzt userInfo als Brücke zu self
private let hotkeyEventTapCallback: CGEventTapCallBack = { _, _, event, refcon in
    guard let refcon else { return Unmanaged.passUnretained(event) }
    Unmanaged<HotkeyService>.fromOpaque(refcon).takeUnretainedValue().handleEvent(event)
    return Unmanaged.passUnretained(event)
}
