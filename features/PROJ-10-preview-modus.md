# PROJ-10 – Preview-Modus

**Status**: Abgeschlossen
**Branch**: main

## Ziel

Opt-in-Modus: Text nach Transkription im Popover bearbeiten, bevor er eingefügt wird.

## Umgesetzte Änderungen

### AppSettings.swift
- `previewEnabled: Bool` (Default: false, UserDefaults-Persistenz)

### AppState.swift
- `handleTranscriptionDone`: bei `previewEnabled` wird `targetApp` gespeichert und nur `transcriptionState = .done` gesetzt – kein sofortiges Einfügen
- `confirmPaste(text:)`: aktiviert Ziel-App, fügt übergebenen Text ein, setzt State auf `.idle`

### PopoverRootView.swift
- Im `.done`-Fall: bei aktivem Preview zeigt sich ein `TextEditor` (minHeight 100, maxHeight 140) + "Einfügen"-Button statt read-only Text
- Popover-Frame: 320 px hoch im Preview-Modus, sonst 270 px
- `@State var editableText` wird bei neuem `.done`-State per `onChange` aktualisiert

### SettingsView.swift
- Toggle "Vorschau vor Einfügen" mit Beschreibungszeile
