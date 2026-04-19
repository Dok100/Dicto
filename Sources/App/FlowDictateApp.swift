import SwiftUI

@main
struct FlowDictateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Kein WindowGroup – reine Menübar-App ohne Hauptfenster.
        // Settings-Scene wird benötigt, damit SwiftUI's App-Protokoll erfüllt ist,
        // öffnet aber kein Fenster von selbst.
        Settings {
            EmptyView()
        }
    }
}
