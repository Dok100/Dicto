import Foundation

final class StatsService: ObservableObject {
    // MARK: – Persistierte Werte

    @Published private(set) var totalDictations: Int = 0
    @Published private(set) var totalWords: Int = 0
    @Published private(set) var transformCount: Int = 0
    @Published private(set) var styleUsage: [String: Int] = [:]
    @Published private(set) var dailyCounts: [String: Int] = [:]

    private let defaults = UserDefaults.standard
    private enum Key {
        static let dictations = "stats.totalDictations"
        static let words = "stats.totalWords"
        static let transform = "stats.transformCount"
        static let style = "stats.styleUsage"
        static let daily = "stats.dailyCounts"
    }

    init() {
        load()
    }

    // MARK: – Aufzeichnen

    func record(text: String, style: String, isTransform: Bool) {
        let words = text.split(separator: " ").count
        totalDictations += 1
        totalWords += words
        if isTransform { transformCount += 1 }
        styleUsage[style, default: 0] += 1
        dailyCounts[todayKey(), default: 0] += 1
        pruneDailyCounts()
        save()
    }

    // MARK: – Berechnete Kennzahlen

    var todayCount: Int {
        dailyCounts[todayKey()] ?? 0
    }

    var thisWeekCount: Int {
        let fmt = isoFormatter()
        return (0..<7).compactMap { offset -> Int? in
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return dailyCounts[fmt.string(from: date)]
        }.reduce(0, +)
    }

    var averageWords: Int {
        totalDictations > 0 ? totalWords / totalDictations : 0
    }

    var favoriteStyle: String {
        styleUsage.max(by: { $0.value < $1.value })?.key ?? "–"
    }

    /// Letzte 7 Tage als (Kurzname, Anzahl)-Paare, aufsteigend (ältester zuerst)
    var last7Days: [(label: String, count: Int)] {
        let iso = isoFormatter()
        let day = DateFormatter()
        day.dateFormat = "E"
        day.locale = Locale(identifier: "de_DE")

        return (0..<7).reversed().map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return (
                label: day.string(from: date),
                count: dailyCounts[iso.string(from: date)] ?? 0)
        }
    }

    // MARK: – Hilfsmethoden

    private func todayKey() -> String {
        isoFormatter().string(from: Date())
    }

    private func isoFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private func pruneDailyCounts() {
        let fmt = isoFormatter()
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else { return }
        let cutoffKey = fmt.string(from: cutoff)
        dailyCounts = dailyCounts.filter { $0.key >= cutoffKey }
    }

    private func save() {
        defaults.set(totalDictations, forKey: Key.dictations)
        defaults.set(totalWords, forKey: Key.words)
        defaults.set(transformCount, forKey: Key.transform)
        if let d = try? JSONEncoder().encode(styleUsage) { defaults.set(d, forKey: Key.style) }
        if let d = try? JSONEncoder().encode(dailyCounts) { defaults.set(d, forKey: Key.daily) }
    }

    private func load() {
        totalDictations = defaults.integer(forKey: Key.dictations)
        totalWords = defaults.integer(forKey: Key.words)
        transformCount = defaults.integer(forKey: Key.transform)
        if let d = defaults.data(forKey: Key.style),
           let v = try? JSONDecoder().decode([String: Int].self, from: d) { styleUsage = v }
        if let d = defaults.data(forKey: Key.daily),
           let v = try? JSONDecoder().decode([String: Int].self, from: d) { dailyCounts = v }
    }
}
