# PROJ-19 – Einstellungs-Tabs + Diktat-Statistiken

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Einstellungsfenster von einer langen Scroll-Seite auf übersichtliche Toolbar-Tabs umstellen,
gleichzeitig Diktat-Statistiken als neuer Tab einführen.

## Umfang

| Bereich | Beschreibung | Status |
|---------|-------------|--------|
| Toolbar-Tabs | NSToolbar mit 4 Tabs (Allgemein / KI / Wörterbuch / Statistiken) | ✅ |
| StatsService | Kumulatives Tracking von Diktaten, Wörtern, Stilen | ✅ |
| Statistiken-Tab | Kennzahlen-Karten + 7-Tage-Balkendiagramm + Stil-Nutzung | ✅ |

## Umgesetzte Änderungen

### SettingsWindowController.swift (Neufassung)
- `NSToolbar` mit `NSToolbarDelegate` – Tabs als Toolbar-Items mit Icon + Label
- `toolbarSelectableItemIdentifiers` aktiviert Radio-Button-Verhalten
- 4 Tabs: `SettingsTab.general / .ai / .dictionary / .stats`
- Lazy `NSHostingController` pro Tab – wird erst beim ersten Wechsel erstellt und gecacht
- Fenster: `.unifiedTitleAndToolbar`, 500×520, `minSize` 440×400

### Neue Tab-Views
- **GeneralSettingsView.swift**: Login, Sprache & Modell, Verhalten
- **AISettingsView.swift**: Ollama Toggle, Modell, Endpoint, System-Prompt
- **DictionarySettingsView.swift**: Einträge, Hinzufügen, Export/Import
- **StatsSettingsView.swift**: Statistiken (neu, siehe unten)

### StatsService.swift (neu)
- Persistiert in `UserDefaults` (5 Keys mit Präfix `stats.`)
- `record(text:style:isTransform:)` – wird aus `AppState` nach jeder Transkription aufgerufen
- Kennzahlen: `totalDictations`, `totalWords`, `transformCount`, `styleUsage`, `dailyCounts`
- `dailyCounts` wird auf 90 Tage beschränkt (automatisches Pruning)
- `last7Days` – Array von `(label, count)` für das Balkendiagramm

### AppState.swift
- `statsService = StatsService()` als neue Property
- `record()` nach `handleTranscriptionDone` (isTransform: false)
- `record()` nach `handleTransformDone` (isTransform: true)

### SettingsView.swift
- Inhalt in 4 separate Views aufgeteilt; Datei ist jetzt nur noch Kommentar-Platzhalter

## Statistiken-Tab: Kennzahlen

| Karte | Berechnung |
|-------|-----------|
| Diktate gesamt | `totalDictations` |
| Heute | `dailyCounts[todayKey]` |
| Diese Woche | Summe der letzten 7 `dailyCounts`-Einträge |
| Wörter gesamt | `totalWords` |
| Ø Wörter/Diktat | `totalWords / totalDictations` |
| Transforms | `transformCount` |

7-Tage-Balkendiagramm: benutzerdefinierter `BarChartView` (kein SwiftUI Charts nötig).
Stil-Nutzung: horizontale Fortschrittsbalken, sortiert nach Häufigkeit.
