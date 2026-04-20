# PROJ-14 – Sprachauswahl für WhisperKit

**Status**: Abgeschlossen
**Branch**: main

## Ziel

WhisperKit direkt in der gewünschten Sprache transkribieren lassen – ohne Ollama-Umweg für Übersetzungen.

## Optionen

| Einstellung | Whisper-Parameter | Verhalten |
|-------------|-------------------|-----------|
| Deutsch | `language: "de"` | Wie bisher (Default) |
| Englisch | `language: "en"` | Direkte englische Transkription |
| Auto | `language: nil` | Whisper erkennt Sprache automatisch (etwas langsamer, bei kurzen Aufnahmen unzuverlässiger) |

## Umgesetzte Änderungen

### WhisperLanguage.swift (neu)
- `enum WhisperLanguage: String, CaseIterable` mit Fällen `german`, `english`, `auto`
- `code: String?` liefert den Whisper-Sprachcode (`nil` für Auto)

### AppSettings.swift
- `whisperLanguage: WhisperLanguage` mit UserDefaults-Persistenz (Default: `.german`)

### WhisperService.swift
- `transcribe(fileURL:model:language:)` nimmt jetzt `WhisperLanguage` entgegen
- `DecodingOptions(task: .transcribe, language: language.code)` – `nil` aktiviert Auto-Erkennung

### AppState.swift
- `settings.whisperLanguage` wird bei `onKeyUp` und `onTransformKeyUp` weitergegeben

### SettingsView.swift
- Radio-Group-Picker direkt unter der Whisper-Modellauswahl
