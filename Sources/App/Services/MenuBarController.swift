import AppKit
import Combine
import SwiftUI

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    private var settingsWindowController: SettingsWindowController?

    init(appState: AppState) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        setupStatusItem()
        setupPopover(appState: appState)

        settingsWindowController = SettingsWindowController(settings: appState.settings)
        appState.onOpenSettings = { [weak self] in
            self?.popover.performClose(nil)
            self?.settingsWindowController?.show()
        }

        // Status-Dot aktualisieren wenn sich Zustand ändert
        appState.$transcriptionState
            .combineLatest(appState.$isRecording, appState.$hasMicrophonePermission)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak appState] _, _, _ in
                guard let self, let appState else { return }
                self.updateStatusDot(appState: appState)
            }
            .store(in: &cancellables)

        // Popover automatisch zeigen wenn Transkription fertig ist
        appState.$transcriptionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                if case .done = state { self?.showPopover() }
            }
            .store(in: &cancellables)

        updateStatusDot(appState: appState)
    }

    // MARK: – Status-Dot

    private func updateStatusDot(appState: AppState) {
        guard let button = statusItem.button else { return }

        let micName: String
        let dotColor: NSColor

        if appState.missingPermission != .none {
            micName = "mic.slash"
            dotColor = .systemRed
        } else if appState.isRecording {
            micName = "mic.fill"
            dotColor = .systemRed
        } else if case .loadingModel = appState.transcriptionState {
            micName = "mic"
            dotColor = .systemOrange
        } else if case .transcribing = appState.transcriptionState {
            micName = "mic"
            dotColor = .systemOrange
        } else if case .error = appState.transcriptionState {
            micName = "mic.slash"
            dotColor = .systemRed
        } else {
            micName = "mic"
            dotColor = .systemGreen
        }

        button.image = NSImage(systemSymbolName: micName, accessibilityDescription: "Dicto")
        button.attributedTitle = NSAttributedString(
            string: " ●",
            attributes: [
                .foregroundColor: dotColor,
                .font: NSFont.systemFont(ofSize: 7)
            ]
        )
    }

    // MARK: – Setup

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Dicto")
        button.imagePosition = .imageLeft
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
