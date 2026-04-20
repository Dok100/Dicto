# PROJ-11 – Wörterbuch (statisch + lernend)

**Status**: Abgeschlossen
**Branch**: main

## Ziel

Falsch erkannte Wörter automatisch ersetzen. Einträge können manuell gepflegt oder automatisch aus Vorschau-Korrekturen gelernt werden.

## Umgesetzte Änderungen

### WordEntry.swift (neu)
- `struct WordEntry: Codable, Identifiable` mit `wrong` und `correct`

### DictionaryService.swift (neu)
- `apply(to:)` – wendet alle Einträge als String-Ersetzungen an (NFC-normalisiert)
- `add(wrong:correct:)` – fügt Eintrag hinzu, dedupliziert nach `wrong`
- `remove(id:)` – löscht Eintrag
- `learnFromDiff(original:edited:)` – lernt 1:1-Wort-Korrekturen aus Vorschau-Bearbeitungen (nur bei gleicher Wortanzahl)
- Persistenz via UserDefaults (JSON)

### AppState.swift
- `dictionaryService` als Eigenschaft
- `handleTranscriptionDone`: Wörterbuch nach Ollama angewendet
- `confirmPaste(original:edited:)`: ruft `learnFromDiff` vor dem Einfügen auf

### SettingsView.swift
- Wörterbuch-Sektion mit Eintrags-Liste, Löschen-Button und Hinzufügen-Formular

### SettingsWindowController.swift
- Nimmt jetzt `AppState` statt nur `AppSettings`, um `DictionaryService` weiterzugeben

## Bekannte Eigenheit: NFD vs NFC (behoben)
WhisperKit liefert Umlaute manchmal als NFD (o + combining diaeresis), während Nutzereingaben NFC verwenden.
Lösung: `precomposedStringWithCanonicalMapping` normalisiert beide Seiten auf NFC vor dem Vergleich.
