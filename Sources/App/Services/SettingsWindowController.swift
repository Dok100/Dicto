import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(settings: AppSettings) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Dicto – Einstellungen"
        window.center()
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: SettingsView(settings: settings)
        )
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
