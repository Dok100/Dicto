# PROJ-15 – Diktat-Verlauf

**Status**: Abgeschlossen
**Branch**: main

## Ziel

Die letzten 20 Diktat-Ergebnisse abrufbar halten, damit kein Text verloren geht.

## Umgesetzte Änderungen

### DictationEntry.swift (neu)
- `struct DictationEntry: Codable, Identifiable` mit `text: String` und `date: Date`

### HistoryService.swift (neu)
- `add(text:)` – fügt Eintrag vorne ein, hält max. 20 Einträge
- `clear()` – löscht den gesamten Verlauf
- Persistenz via UserDefaults (JSON)

### AppState.swift
- `historyService: HistoryService` als Eigenschaft
- Eintrag wird nach jedem erfolgreichen Paste hinzugefügt:
  - `handleTranscriptionDone` (direkt eingefügt)
  - `confirmPaste` (Preview-Modus, nach Nutzerbestätigung)
  - `handleTransformDone` (Transform-Modus)

### PopoverRootView.swift
- Uhr-Button im Footer (neben Zahnrad) öffnet/schließt die Verlaufsliste
- Einträge zeigen Datum/Uhrzeit (relativ) + Text mit `textSelection(.enabled)`
- Verlauf schließt automatisch wenn ein neues Ergebnis eintrifft
