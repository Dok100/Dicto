import Foundation

public final class HistoryService: ObservableObject {
    @Published public private(set) var entries: [DictationEntry] = []

    private let maxEntries = 20
    private let storageKey = StorageKey.Defaults.dictationHistory

    public init() {
        load()
    }

    public func add(text: String) {
        guard !text.isEmpty else { return }
        entries.insert(DictationEntry(text: text, date: Date()), at: 0)
        if entries.count > maxEntries { entries = Array(entries.prefix(maxEntries)) }
        save()
    }

    public func clear() {
        entries = []
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DictationEntry].self, from: data) else { return }
        entries = decoded
    }
}
