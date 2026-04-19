import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let state = AppState()
        appState = state
        menuBarController = MenuBarController(appState: state)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
