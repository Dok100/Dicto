import AppKit
import SwiftUI

final class OnboardingWindowController: NSWindowController {
    static var isNeeded: Bool {
        !UserDefaults.standard.bool(forKey: StorageKey.Defaults.onboardingCompleted)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: StorageKey.Defaults.onboardingCompleted)
    }

    init(settings: AppSettings, onComplete: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.center()

        let view = OnboardingView(settings: settings) {
            OnboardingWindowController.markCompleted()
            onComplete()
        }
        window.contentViewController = NSHostingController(rootView: view)
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func show() {
        // Größe explizit setzen – NSHostingController meldet beim ersten Rendern oft (0,0)
        window?.setContentSize(NSSize(width: 480, height: 560))
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
