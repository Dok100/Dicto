import AppKit
import SwiftUI

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Dicto")
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 280, height: 180)
        // .transient schließt den Popover automatisch, wenn der Nutzer woanders klickt
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PopoverRootView())
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Fenster in den Vordergrund holen, damit Tastatur-Fokus funktioniert
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
