# Dicto

Native macOS-Menübar-App für Push-to-Talk-Diktat – vollständig lokal auf Apple Silicon.

## Funktionsweise

Fn-Taste gedrückt halten → Aufnahme läuft → loslassen → Transkription via WhisperKit → Text wird an der Cursor-Position eingefügt.

Optional: Glättung des transkribierten Texts über Ollama (Modell `glm-4.7-flash`) lokal auf dem Gerät.

## Stack

- Swift / SwiftUI, macOS 14+
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) – lokale Spracherkennung (Modell: `openai_whisper-large-v3-turbo`, Sprache: Deutsch)
- [Ollama](https://ollama.ai) – optionale Text-Glättung (`glm-4.7-flash`, `http://localhost:11434`)
- XcodeGen, swiftformat

## Voraussetzungen

- macOS 14.0+, Apple Silicon
- Xcode 15+
- `xcodegen` und `swiftformat` (`brew install xcodegen swiftformat`)
- Ollama (optional, für Text-Glättung)

## Schnellstart

```bash
make install    # xcodegen + swiftformat installieren (einmalig)
make generate   # Xcode-Projekt aus project.yml erzeugen
make build      # App bauen
```

## Phasenplan

| Phase | Beschreibung | Status |
|-------|-------------|--------|
| PROJ-1 | Menübar-App-Gerüst (Icon, Popover, Projekt-Setup) | In Arbeit |
| PROJ-2 | Globaler Fn-Hotkey + Audio-Aufnahme | Offen |
| PROJ-3 | WhisperKit-Transkription | Offen |
| PROJ-4 | Text-Einfügung via Pasteboard | Offen |
| PROJ-5 | Post-Processor-Protokoll + PassthroughPostProcessor | Offen |
| PROJ-6 | OllamaPostProcessor | Offen |
| PROJ-7 | Einstellungsbereich | Offen |

## Datenschutz

Audio-Daten verlassen das Gerät nie. Transkription und optionale Glättung laufen vollständig lokal.
