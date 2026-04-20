import Foundation

final class DictionaryService: ObservableObject {
    @Published private(set) var entries: [WordEntry] = []

    private let storageKey = "dictionaryEntries"

    init() { load() }

    func apply(to text: String) -> String {
        // NFC-Normalisierung damit WhisperKit-NFD-Umlaute mit Einträgen übereinstimmen
        let normalized = text.precomposedStringWithCanonicalMapping
        return entries.reduce(normalized) { result, entry in
            guard !entry.wrong.isEmpty else { return result }
            return result.replacingOccurrences(
                of: entry.wrong.precomposedStringWithCanonicalMapping,
                with: entry.correct
            )
        }
    }

    func add(wrong: String, correct: String) {
        let w = wrong.trimmingCharacters(in: .whitespacesAndNewlines)
                     .precomposedStringWithCanonicalMapping
        let c = correct.trimmingCharacters(in: .whitespacesAndNewlines)
                       .precomposedStringWithCanonicalMapping
        guard !w.isEmpty, !c.isEmpty, w != c else { return }
        guard !entries.contains(where: { $0.wrong == w }) else { return }
        entries.append(WordEntry(wrong: w, correct: c))
        save()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    // Lernt 1:1-Wort-Korrekturen aus Vorschau-Bearbeitungen.
    // Funktioniert nur wenn Wortanzahl identisch ist (einfache Heuristik).
    func learnFromDiff(original: String, edited: String) {
        let origWords = original.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let editWords = edited.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard origWords.count == editWords.count else { return }
        let strip = { (s: String) in s.trimmingCharacters(in: .punctuationCharacters) }
        for (o, e) in zip(origWords, editWords) where o != e {
            add(wrong: strip(o), correct: strip(e))
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WordEntry].self, from: data) else { return }
        entries = decoded
    }
}
