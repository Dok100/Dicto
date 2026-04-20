# Dicto

Native macOS-Menübar-App für Push-to-Talk-Diktat – vollständig lokal auf Apple Silicon.

## Funktionsweise

Fn-Taste gedrückt halten → Aufnahme läuft → loslassen → Transkription via WhisperKit → optional Glättung via Ollama → Text wird an der Cursor-Position eingefügt.

## Stack

- Swift / SwiftUI, macOS 14+
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) – lokale Spracherkennung (Modell: `large-v3`, Sprache: Deutsch)
- [Ollama](https://ollama.ai) – optionale Textglättung (`glm4`, `http://localhost:11434`)
- XcodeGen, swiftformat

## Voraussetzungen

- macOS 14.0+, Apple Silicon
- Xcode 15+
- `xcodegen` und `swiftformat` (`brew install xcodegen swiftformat`)
- Ollama mit `glm4` (optional, für Textglättung): `ollama pull glm4`

## Schnellstart

```bash
make install    # xcodegen + swiftformat installieren (einmalig)
make generate   # Xcode-Projekt aus project.yml erzeugen
make build      # App bauen
```

## Berechtigungen

Beim ersten Start fordert Dicto drei Berechtigungen an:

| Berechtigung | Zweck |
|---|---|
| Mikrofon | Aufnahme |
| Eingabehilfen | Text automatisch einfügen (Cmd+V-Simulation) |
| Eingabe-Überwachung | Globalen Fn-Hotkey erkennen |

## Phasenplan

| Phase | Beschreibung | Status |
|-------|-------------|--------|
| PROJ-1 | Menübar-App-Gerüst (Icon, Popover, Projekt-Setup) | Abgeschlossen |
| PROJ-2 | Globaler Fn-Hotkey + Audio-Aufnahme | Abgeschlossen |
| PROJ-3 | WhisperKit-Transkription | Abgeschlossen |
| PROJ-4 | Text-Einfügung via Pasteboard + CGEvent | Abgeschlossen |
| PROJ-5 | TextPostProcessor-Protokoll + PassthroughPostProcessor | Abgeschlossen |
| PROJ-6 | OllamaPostProcessor mit Fallback | Abgeschlossen |
| PROJ-7 | Einstellungsfenster (Toggle, Prompt-Editor, Modell/Endpoint) | Abgeschlossen |
| PROJ-8 | Stil-Auswahl im Popover (Neutral / Formell / Locker / Empathisch) | Offen |
| PROJ-9 | Whisper-Modellauswahl | Offen |
| PROJ-10 | Preview-Modus (Text vor Einfügen editierbar) | Offen |
| PROJ-11 | Wörterbuch (statisch + lernend via Preview) | Offen |
| PROJ-12 | Transform-Modus (Fn+Alt: Selektion + Befehl) | Offen |

## Datenschutz

Audio-Daten verlassen das Gerät nie. Transkription und optionale Glättung laufen vollständig lokal.
