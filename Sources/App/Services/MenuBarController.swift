import AppKit
import Combine
import SwiftUI

final class MenuBarController {
    private let statusItem: NSStatusItem
    private var panel: NSPanel!
    private var cancellables = Set<AnyCancellable>()
    private var clickOutsideMonitor: Any?
    private var settingsWindowController: SettingsWindowController?

    init(appState: AppState) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItem()
        setupPanel(appState: appState)

        settingsWindowController = SettingsWindowController(appState: appState)
        appState.onOpenSettings = { [weak self] in
            self?.hidePanel()
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

        // Panel automatisch zeigen wenn Transkription fertig ist
        appState.$transcriptionState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                if case .done = state { self?.showPanel() }
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
        button.action = #selector(togglePanel)
        button.target = self
    }

    private func setupPanel(appState: AppState) {
        // .nonactivatingPanel: Panel zeigen ohne die Ziel-App zu deaktivieren.
        // Ohne das würde frontmostApplication auf Dicto zeigen und Diktieren wäre kaputt.
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 320),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = ""
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.minSize = NSSize(width: 280, height: 240)
        panel.becomesKeyOnlyIfNeeded = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.contentViewController = NSHostingController(
            rootView: PopoverRootView()
                .environmentObject(appState)
                .environment(\.controlActiveState, .key)
        )
    }

    // MARK: – Panel anzeigen / verstecken

    private func showPanel() {
        positionPanel()
        panel.orderFront(nil)

        guard clickOutsideMonitor == nil else { return }
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hidePanel()
        }
    }

    private func hidePanel() {
        panel.orderOut(nil)
        if let m = clickOutsideMonitor { NSEvent.removeMonitor(m) }
        clickOutsideMonitor = nil
    }

    private func positionPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window,
              let screen = buttonWindow.screen else { return }

        let buttonFrame = button.convert(button.bounds, to: nil)
        let screenFrame = buttonWindow.convertToScreen(buttonFrame)

        var x = screenFrame.midX - panel.frame.width / 2
        let y = screenFrame.minY - panel.frame.height - 6

        // Nicht über Bildschirmränder hinaus
        x = min(x, screen.visibleFrame.maxX - panel.frame.width)
        x = max(x, screen.visibleFrame.minX)

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }
}
