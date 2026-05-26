import AppKit
import SwiftUI

final class HelpWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window.title = "Dicto – Hilfe"
        window.minSize = NSSize(width: 600, height: 400)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("DictoHelp")
        window.center()
        window.contentViewController = NSHostingController(rootView: HelpView())

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func show() {
        if let w = window, !w.isVisible,
           UserDefaults.standard.object(forKey: "NSWindow Frame DictoHelp") == nil
        {
            w.setContentSize(NSSize(width: 720, height: 520))
            w.center()
        }
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
