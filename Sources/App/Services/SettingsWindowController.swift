import AppKit
import SwiftUI

// MARK: – Tab-Definition

private enum SettingsTab: String, CaseIterable {
    case general    = "general"
    case ai         = "ai"
    case dictionary = "dictionary"
    case stats      = "stats"

    var label: String {
        switch self {
        case .general:    return "Allgemein"
        case .ai:         return "KI"
        case .dictionary: return "Wörterbuch"
        case .stats:      return "Statistiken"
        }
    }

    var icon: String {
        switch self {
        case .general:    return "gearshape"
        case .ai:         return "brain"
        case .dictionary: return "text.book.closed"
        case .stats:      return "chart.bar"
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

    init(appState: AppState) {
        self.appState = appState

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 520),
            styleMask: [.titled, .closable, .resizable, .unifiedTitleAndToolbar],
            backing: .buffered,
            defer: false
        )
        window.title = "Dicto – Einstellungen"
        window.minSize = NSSize(width: 440, height: 400)
        window.isReleasedWhenClosed = false
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

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: – Tab-Wechsel

    @objc private func tabSelected(_ item: NSToolbarItem) {
        guard let tab = SettingsTab(rawValue: item.itemIdentifier.rawValue),
              tab != currentTab else { return }
        currentTab = tab
        window?.contentViewController = viewController(for: tab)
    }

    private func viewController(for tab: SettingsTab) -> NSViewController {
        switch tab {
        case .general:    return vcGeneral
        case .ai:         return vcAI
        case .dictionary: return vcDictionary
        case .stats:      return vcStats
        }
    }

    // MARK: – NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let tab = SettingsTab(rawValue: itemIdentifier.rawValue) else { return nil }

        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label  = tab.label
        item.image  = NSImage(systemSymbolName: tab.icon, accessibilityDescription: tab.label)
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

    private func makeVC<V: View>(_ view: V) -> NSViewController {
        NSHostingController(rootView: view)
    }
}
