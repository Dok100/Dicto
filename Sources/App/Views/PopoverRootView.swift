import SwiftUI

struct PopoverRootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Dicto")
                .font(.headline)

            Text("Push-to-Talk-Diktat")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Divider()

            Button("Beenden") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 280, height: 180)
    }
}
