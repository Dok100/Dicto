import AppKit
import Combine
import SwiftUI

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellable: AnyCancellable?
    private var settingsWindowController: SettingsWindowController?

    init(appState: AppState) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        setupStatusItem()
        setupPopover(appState: appState)

        settingsWindowController = SettingsWindowController(settings: appState.settings)
        appState.onOpenSettings = { [weak self] in
            self?.popover.performClose(nil)
            self?.settingsWindowController?.show()
        }

        cancellable = appState.$transcriptionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                if case .done = state { self?.showPopover() }
            }
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Dicto")
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupPopover(appState: AppState) {
        popover.contentSize = NSSize(width: 280, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverRootView().environmentObject(appState)
        )
    }

    private func showPopover() {
        guard !popover.isShown, let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }
}
