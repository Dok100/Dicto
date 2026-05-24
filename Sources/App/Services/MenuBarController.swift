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
    private var onboardingWindowController: OnboardingWindowController?

    init(appState: AppState) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItem()
        setupPanel(appState: appState)

        settingsWindowController = SettingsWindowController(appState: appState)
        appState.onOpenSettings = { [weak self] in
            self?.hidePanel()
            self?.settingsWindowController?.show()
        }

        // Onboarding beim ersten Start anzeigen
        if OnboardingWindowController.isNeeded {
            onboardingWindowController = OnboardingWindowController { [weak self] in
                self?.onboardingWindowController?.close()
                self?.onboardingWindowController = nil
            }
            // Kurze Verzögerung damit die Menübar fertig aufgebaut ist
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.onboardingWindowController?.show()
            }
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
            .combineLatest(appState.$isRecording, appState.$isTransformRecording)
            .receive(on: RunLoop.main)
            .sink { [weak self, weak appState] _, _, _ in
                guard let self, let appState else { return }
                self.updateStatusDot(appState: appState)
            }
            .store(in: &cancellables)

        updateStatusDot(appState: appState)
    }

    // MARK: – Menübar-Icon: PNG-Template-Assets (Aperture-D Design)

    private func updateStatusDot(appState: AppState) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        if appState.isRecording {
            // Aufnahme läuft: ausgefülltes Mikrofon
            symbolName = appState.isTransformRecording ? "wand.and.sparkles" : "mic.fill"
        } else if case .loadingModel = appState.transcriptionState {
            // Modell wird geladen: Wellenform
            symbolName = "waveform"
        } else if case .transcribing = appState.transcriptionState {
            // Transkription läuft: Wellenform
            symbolName = "waveform"
        } else if case .error = appState.transcriptionState {
            symbolName = "exclamationmark.circle"
        } else {
            // Idle / Done: normales Mikrofon
            symbolName = "mic"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        button.image?.isTemplate = true   // macOS töngt für Dark/Light-Mode
        button.title = ""
    }

    // MARK: – Setup

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.imagePosition = .imageOnly
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
        panel.minSize = NSSize(width: 320, height: 400)
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
        let visible = screen.visibleFrame

        var x = screenFrame.midX - panel.frame.width / 2
        var y = screenFrame.minY - panel.frame.height - 6

        // Horizontal: nicht über Bildschirmränder
        x = min(x, visible.maxX - panel.frame.width)
        x = max(x, visible.minX)

        // Vertikal: Panel-Unterkante nicht unter sichtbaren Bereich (Dock etc.)
        y = max(y, visible.minY)

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
