# PROJ-7 – Einstellungen

## Ziel

Persistente Einstellungen mit eigenem Fenster, erreichbar über ein Zahnrad-Icon im Popover.

## Einstellungen

| Key | Typ | Default |
|---|---|---|
| `ollamaEnabled` | Bool | true |
| `ollamaBaseURL` | String | http://localhost:11434 |
| `ollamaModel` | String | glm4 |
| `ollamaPrompt` | String | (langer System-Prompt) |

## Architektur

- `AppSettings`: ObservableObject mit @AppStorage → automatisch in UserDefaults persistiert
- `SettingsView`: SwiftUI-Formular (Toggle, TextFields, TextEditor)
- `SettingsWindowController`: öffnet NSWindow mit NSHostingController
- `AppState`: beobachtet AppSettings via Combine, setzt postProcessor entsprechend
- `OllamaPostProcessor`: bekommt systemPrompt als Parameter (nicht mehr hardcoded)

## Dateien

| Datei | Änderung |
|---|---|
| `Sources/App/Models/AppSettings.swift` | Neu |
| `Sources/App/Views/SettingsView.swift` | Neu |
| `Sources/App/Services/SettingsWindowController.swift` | Neu |
| `Sources/App/Models/AppState.swift` | AppSettings integrieren |
| `Sources/App/PostProcessors/OllamaPostProcessor.swift` | systemPrompt als Parameter |
| `Sources/App/Views/PopoverRootView.swift` | Zahnrad-Button |

## Status

In Arbeit
