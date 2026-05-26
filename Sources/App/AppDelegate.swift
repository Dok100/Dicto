import AppKit
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appState: AppState?

    // Sparkle: verwaltet Update-Checks und UI automatisch
    private var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = AppState()
        appState = state
        menuBarController = MenuBarController(appState: state)

        // Sparkle initialisieren – prüft SUFeedURL aus Info.plist,
        // startet automatisch einen Update-Check im Hintergrund
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Wird vom Menüpunkt „Nach Updates suchen" aufgerufen
    @objc func checkForUpdates(_ sender: Any) {
        updaterController?.checkForUpdates(sender)
    }
}
