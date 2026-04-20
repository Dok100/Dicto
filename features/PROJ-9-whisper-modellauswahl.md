# PROJ-9 – Whisper-Modellauswahl

**Status**: Abgeschlossen
**Branch**: proj-2-hotkey-audio (auf main)

## Ziel

Nutzer kann in den Einstellungen zwischen Whisper-Modellen wählen, um Geschwindigkeit vs. Qualität abzuwägen.

## Umgesetzte Änderungen

### WhisperModel.swift (neu)
- `enum WhisperModel: String, CaseIterable` mit Fällen `base` und `largev3`
- `label`-Property für UI-Anzeige mit Größen- und Geschwindigkeitshinweis

### AppSettings.swift
- Neues `@Published var whisperModel: WhisperModel` mit UserDefaults-Persistenz
- Default: `.largev3`

### WhisperService.swift
- `loadedModel: WhisperModel?` merkt sich das geladene Modell
- `loadModelIfNeeded(model:)` lädt neu wenn sich das Modell geändert hat
- `transcribe(fileURL:model:)` übergibt Modell, lädt bei Bedarf nach

### AppState.swift
- Übergibt `settings.whisperModel` an `transcribe` und `loadModelIfNeeded`

### SettingsView.swift
- Radio-Group-Picker für `WhisperModel.allCases` oben in den Einstellungen
- Hinweis: "Modellwechsel wird beim nächsten Diktat angewendet."

## Modellübersicht

| Modell | WhisperKit-Name | Größe | Dauer (M4) |
|--------|-----------------|-------|------------|
| Base   | `base`          | ~150 MB | ~1–2 s  |
| Large v3 | `large-v3`    | ~3 GB   | ~8–15 s |
