# PROJ-16 – Wörterbuch Export/Import

**Status**: Abgeschlossen
**Branch**: main

## Ziel

Wörterbuch-Einträge als JSON-Datei sichern und auf anderen Macs wiederherstellen.

## Umgesetzte Änderungen

### SettingsView.swift
- "Exportieren"-Button: öffnet `NSSavePanel`, speichert `[WordEntry]` als JSON
- "Importieren"-Button: öffnet `NSOpenPanel`, liest JSON und fügt neue Einträge via `dictionaryService.add()` hinzu
- Duplikate (gleicher `wrong`-Wert) werden beim Import übersprungen

## Dateiformat

Standardmäßiges JSON-Array der `WordEntry`-Struktur:
```json
[
  { "id": "...", "wrong": "Whisper Kit", "correct": "WhisperKit" },
  { "id": "...", "wrong": "Ödheim", "correct": "Oedheim" }
]
```
