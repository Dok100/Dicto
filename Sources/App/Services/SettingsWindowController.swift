import AppKit
import SwiftUI

// MARK: – Tab-Definition

private enum SettingsTab: String, CaseIterable {
    case general
    case ai
    case dictionary
    case stats
    case license

    var label: String {
        switch self {
        case .general:  "Allgemein"
        case .ai:       "KI"
        case .dictionary: "Wörterbuch"
        case .stats:    "Statistiken"
        case .license:  "Lizenz"
        }
    }

    var icon: String {
        switch self {
        case .general:  "gearshape"
        case .ai:       "brain"
        case .dictionary: "text.book.closed"
        case .stats:    "chart.bar"
        case .license:  "seal"
        }
    }

    var toolbarIdentifier: NSToolbarItem.Identifier {
        NSToolbarItem.Identifier(rawValue)
    }
}

// MARK: – WindowController

final class SettingsWindowController: NSWindowController, NSToolbarDelegate {
    private let appState: AppState
    private var currentTab: SettingsTab = .general

    // Lazy ViewControllers – werden beim ersten Wechsel erstellt und gecacht
    private lazy var vcGeneral    = makeVC(GeneralSettingsView(settings: appState.settings))
    private lazy var vcAI         = makeVC(AISettingsView(settings: appState.settings))
    private lazy var vcDictionary = makeVC(DictionarySettingsView(dictionaryService: appState.dictionaryService))
    private lazy var vcStats      = makeVC(StatsSettingsView(stats: appState.statsService))
    private lazy var vcLicense    = makeVC(LicenseSettingsView())

    init(appState: AppState) {
        self.appState = appState

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
            styleMask: [.titled, .closable, .resizable, .unifiedTitleAndToolbar],
            backing: .buffered,
            defer: false)
        window.title = "Dicto – Einstellungen"
        window.minSize = NSSize(width: 440, height: 400)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("DictoSettings")
        window.center()

        super.init(window: window)

        // Toolbar aufbauen
        let toolbar = NSToolbar(identifier: "DictoSettingsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.selectedItemIdentifier = SettingsTab.general.toolbarIdentifier
        window.toolbar = toolbar

        // Initial-Tab anzeigen
        window.contentViewController = vcGeneral
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    func show() {
        // Beim ersten Öffnen (kein gespeicherter Frame) Mindestgröße garantieren,
        // damit NSHostingController-Views vollständig sichtbar sind.
        if let w = window, !w.isVisible,
           UserDefaults.standard.object(forKey: "NSWindow Frame DictoSettings") == nil
        {
            w.setContentSize(NSSize(width: 500, height: 520))
            w.center()
        }
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: – Tab-Wechsel

    @objc
    private func tabSelected(_ item: NSToolbarItem) {
        guard let tab = SettingsTab(rawValue: item.itemIdentifier.rawValue),
              tab != currentTab else { return }
        currentTab = tab

        // Aktuelle Größe merken – NSHostingController meldet beim ersten Rendern (0,0)
        // und würde das Fenster beim ViewController-Wechsel auf winzig schrumpfen.
        let size = window?.contentView?.frame.size ?? NSSize(width: 500, height: 520)
        window?.contentViewController = viewController(for: tab)
        window?.setContentSize(size)
    }

    private func viewController(for tab: SettingsTab) -> NSViewController {
        switch tab {
        case .general:    vcGeneral
        case .ai:         vcAI
        case .dictionary: vcDictionary
        case .stats:      vcStats
        case .license:    vcLicense
        }
    }

    // MARK: – NSToolbarDelegate

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem?
    {
        guard let tab = SettingsTab(rawValue: itemIdentifier.rawValue) else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.label
        item.image = NSImage(systemSymbolName: tab.icon, accessibilityDescription: tab.label)
        item.action = #selector(tabSelected(_:))
        item.target = self
        return item
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarIdentifier)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarIdentifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map(\.toolbarIdentifier)
    }

    // MARK: – Hilfsfunktion

    private func makeVC(_ view: some View) -> NSViewController {
        NSHostingController(rootView: view)
    }
}
