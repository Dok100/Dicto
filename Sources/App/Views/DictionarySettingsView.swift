import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DictionarySettingsView: View {
    @ObservedObject var dictionaryService: DictionaryService

    @State private var newWrong   = ""
    @State private var newCorrect = ""

    var body: some View {
        Form {
            Section {
                Text("Falsch erkannte Wörter automatisch ersetzen. Korrekturen im Vorschau-Modus werden automatisch gelernt.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !dictionaryService.entries.isEmpty {
                    ForEach(dictionaryService.entries) { entry in
                        HStack(spacing: 8) {
                            Text(entry.wrong)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.tertiary)
                                .font(.caption)
                            Text(entry.correct)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button {
                                dictionaryService.remove(id: entry.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .font(.callout)
                    }
                }

                // Neuen Eintrag hinzufügen
                HStack(spacing: 6) {
                    TextField("Falsch", text: $newWrong)
                        .textFieldStyle(.roundedBorder)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                    TextField("Richtig", text: $newCorrect)
                        .textFieldStyle(.roundedBorder)
                    Button("Hinzufügen") {
                        dictionaryService.add(wrong: newWrong, correct: newCorrect)
                        newWrong   = ""
                        newCorrect = ""
                    }
                    .disabled(
                        newWrong.trimmingCharacters(in: .whitespaces).isEmpty ||
                        newCorrect.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                }

                HStack(spacing: 8) {
                    Button("Exportieren") { exportDictionary() }
                    Button("Importieren") { importDictionary() }
                }
                .font(.caption)
            } header: {
                Text("Wörterbuch")
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Export / Import

    private func exportDictionary() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "dicto-woerterbuch.json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let data = try? JSONEncoder().encode(dictionaryService.entries) {
                try? data.write(to: url)
            }
        }
    }

    private func importDictionary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let data = try? Data(contentsOf: url),
                  let entries = try? JSONDecoder().decode([WordEntry].self, from: data)
            else { return }
            for entry in entries {
                dictionaryService.add(wrong: entry.wrong, correct: entry.correct)
            }
        }
    }
}
