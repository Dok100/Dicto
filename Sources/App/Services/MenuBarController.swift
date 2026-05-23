import AppKit
import Combine
import SwiftUI

final class MenuBarController {
    private let statusItem: NSStatusItem
    private var panel: NSPanel!
    private var cancellables = Set<AnyCancellable>()
    private var clickOutsideMonitor: Any?
    private var cmdReturnMonitor: Any?
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

        // Panel automatisch öffnen wenn Vorschau nötig ist
        appState.$transcriptionState
            .receive(on: RunLoop.main)
            .sink { [weak self, weak appState] state in
                guard let self, let appState else { return }
                if case .done = state,
                   appState.settings.previewEnabled || appState.isTransformResult {
                    self.showPanel()
                }
            }
            .store(in: &cancellables)

        // Status-Dot aktualisieren wenn sich Zustand ändert
        appState.$transcriptionState
            .combineLatest(appState.$isRecording, appState.$hasMicrophonePermission, appState.$isTransformMode)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak appState] _, _, _, _ in
                guard let self, let appState else { return }
                self.updateStatusDot(appState: appState)
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
        } else if appState.isTransformMode {
            // Transformation (Aufnahme + Verarbeitung): lila
            micName = "wand.and.sparkles"
            dotColor = .systemPurple
        } else if appState.isRecording {
            // Diktat-Aufnahme: rot
            micName = "mic.fill"
            dotColor = .systemRed
        } else if case .loadingModel = appState.transcriptionState {
            // Modell lädt: orange
            micName = "mic"
            dotColor = .systemOrange
        } else if case .transcribing = appState.transcriptionState {
            // Transkription läuft: orange
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
        // .fullSizeContentView: Inhalt füllt die gesamte Fensterfläche (inkl. Titelleiste),
        // nötig damit das SwiftUI-Material bis an den Rand reicht.
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 420),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = ""
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        // Frosted-glass: SwiftUI .regularMaterial übernimmt die Hintergrunddarstellung
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.minSize = NSSize(width: 280, height: 260)
        panel.becomesKeyOnlyIfNeeded = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.setFrameAutosaveName("DictoPanel")
        panel.contentViewController = NSHostingController(
            rootView: PopoverRootView().environmentObject(appState)
        )
    }

    // MARK: – Panel anzeigen / verstecken

    private func showPanel() {
        // Nur beim ersten Anzeigen positionieren; danach gilt die gespeicherte Position
        if !panel.isVisible && UserDefaults.standard.object(forKey: "NSWindow Frame DictoPanel") == nil {
            positionPanel()
        }
        panel.orderFront(nil)
        // makeKey auf nonactivatingPanel: Panel bekommt Tastaturfokus,
        // aber Dicto wird nicht zur frontmostApplication → targetApp bleibt korrekt
        panel.makeKey()

        guard clickOutsideMonitor == nil else { return }
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.hidePanel()
        }
        // ⌘+Return: nonactivatingPanel empfängt keine Tastatur-Events solange Dicto
        // nicht die aktive App ist – daher globaler Monitor statt .keyboardShortcut()
        cmdReturnMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
                  event.keyCode == 36 else { return }
            NotificationCenter.default.post(name: .dictoCmdReturn, object: nil)
        }
    }

    private func hidePanel() {
        panel.orderOut(nil)
        if let m = clickOutsideMonitor { NSEvent.removeMonitor(m) }
        if let m = cmdReturnMonitor { NSEvent.removeMonitor(m) }
        cmdReturnMonitor = nil
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

extension Notification.Name {
    static let dictoCmdReturn = Notification.Name("DictoCmdReturn")
}
