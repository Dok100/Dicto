import SwiftUI

struct StatsSettingsView: View {
    @ObservedObject var stats: StatsService

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ── Kennzahlen-Karten ──────────────────────────────────────────
                HStack(spacing: 12) {
                    statCard(
                        value: stats.totalDictations,
                        label: "Diktate gesamt",
                        icon: "mic.fill",
                        color: .accentColor)
                    statCard(
                        value: stats.todayCount,
                        label: "Heute",
                        icon: "sun.max.fill",
                        color: .orange)
                    statCard(
                        value: stats.thisWeekCount,
                        label: "Diese Woche",
                        icon: "calendar",
                        color: .green)
                }

                HStack(spacing: 12) {
                    statCard(
                        value: stats.totalWords,
                        label: "Wörter gesamt",
                        icon: "text.alignleft",
                        color: .purple)
                    statCard(
                        value: stats.averageWords,
                        label: "Ø Wörter/Diktat",
                        icon: "chart.bar.fill",
                        color: .teal)
                    statCard(
                        value: stats.transformCount,
                        label: "Transforms",
                        icon: "wand.and.sparkles",
                        color: .pink)
                }

                // ── 7-Tage-Balkendiagramm ─────────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("Letzte 7 Tage")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)

                    BarChartView(data: stats.last7Days)
                        .frame(height: 100)
                }
                .padding(16)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))

                // ── Meistgenutzter Stil ───────────────────────────────────────
                if !stats.styleUsage.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Stil-Nutzung")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)

                        let total = max(stats.styleUsage.values.reduce(0, +), 1)
                        ForEach(stats.styleUsage.sorted(by: { $0.value > $1.value }), id: \.key) { key, count in
                            VStack(spacing: 4) {
                                HStack {
                                    Text(key.capitalized)
                                        .font(.callout)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.callout.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                GeometryReader { geo in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.accentColor.opacity(0.7))
                                        .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            Color.accentColor.opacity(0.15),
                                            in: RoundedRectangle(cornerRadius: 3))
                                }
                                .frame(height: 6)
                            }
                        }
                    }
                    .padding(16)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }

                // ── Leer-Zustand ──────────────────────────────────────────────
                if stats.totalDictations == 0 {
                    ContentUnavailableView(
                        "Noch keine Daten",
                        systemImage: "chart.bar",
                        description: Text("Starte dein erstes Diktat, um Statistiken zu sehen."))
                        .frame(maxHeight: .infinity)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: – Kennzahlen-Karte

    private func statCard(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: – Balkendiagramm

private struct BarChartView: View {
    let data: [(label: String, count: Int)]

    private var maxCount: Int {
        max(data.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(data, id: \.label) { item in
                VStack(spacing: 4) {
                    if item.count > 0 {
                        Text("\(item.count)")
                            .font(.system(size: 9).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.accentColor.opacity(0.8))
                                .frame(height: max(geo.size.height * CGFloat(item.count) / CGFloat(maxCount), 3))
                        }
                    }
                    Text(item.label)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
