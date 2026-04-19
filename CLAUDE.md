# CLAUDE.md – Dicto

Persistenter Kontext für Claude Code über Sessions hinweg.

## Projekt-Übersicht

Native macOS-Menübar-App für Push-to-Talk-Diktat, vollständig lokal auf Apple Silicon.
Fn-Taste → Aufnahme → WhisperKit-Transkription → Text an Cursor-Position einfügen.
Optional: Glättung via Ollama (glm-4.7-flash, http://localhost:11434).

## Aktueller Phasenstand

**Aktive Phase**: Alle Phasen abgeschlossen
**Stand**: PROJ-1–PROJ-7 abgeschlossen.

| Phase | Status |
|-------|--------|
| PROJ-1 Menübar-App-Gerüst | Abgeschlossen |
| PROJ-2 Fn-Hotkey + Audio | Abgeschlossen |
| PROJ-3 WhisperKit | Abgeschlossen |
| PROJ-4 Text-Einfügung | Abgeschlossen |
| PROJ-5 PostProcessor-Protokoll | Abgeschlossen |
| PROJ-6 OllamaPostProcessor | Abgeschlossen |
| PROJ-7 Einstellungen | Abgeschlossen |
| PROJ-5 PostProcessor-Protokoll | Offen |
| PROJ-6 OllamaPostProcessor | Offen |
| PROJ-7 Einstellungen | Offen |

## Nutzer-Kontext

- Technischer Anfänger in Swift, aber erfahren mit Projekt-Struktur (hat FRITZ!Box Monitor App gebaut)
- Swift-Spezifika (Actors, Combine, async/await-Edges) kurz erläutern
- macOS-API-Fallstricke (CGEventTap, NSPasteboard, etc.) proaktiv erklären
- Hardware: MacBook Pro M4, 48 GB RAM, macOS Sequoia
- Xcode, XcodeGen, swiftformat sind installiert
- Ollama läuft lokal mit glm-4.7-flash

## Projekt-Konventionen

- XcodeGen: `project.yml` ist Single Source of Truth, `.xcodeproj` wird ignoriert
- Makefile mit Targets: `install`, `generate`, `format`, `build`, `test`, `clean`
- Feature-Branches: `proj-N-slug`, Merge nach main bei Phasenabschluss
- Commit-Messages: `feat(scope): beschreibung` oder `docs: beschreibung`
- Kein App-Store, keine Sandbox, kein GitHub Actions CI

## Offene Fragen / Blocker

- Accessibility-Permission (Eingabehilfen): Nach XcodeGen-Regenerierung ändert sich der App-Pfad → alten Eintrag löschen, App neu starten, System-Prompt bestätigen.
- PostProcessor (PROJ-5): Protokoll so designen dass Passthrough + Ollama einfach austauschbar sind.

## Stack-Versionen

- Swift 5.10
- macOS 14.0+ Deployment Target
- Xcode 15+
- WhisperKit: aktuell (main branch, SPM)
- Ollama: lokal, glm4 (Ollama-Modellname: glm4, 5.5 GB)

## Wichtige Dateipfade

| Datei | Zweck |
|-------|-------|
| `project.yml` | XcodeGen-Konfiguration |
| `Makefile` | Build-Targets |
| `Sources/App/` | Swift-Quellcode |
| `tests/AppTests/` | Unit-Tests |
| `docs/decision-log.md` | Architekturentscheidungen |
| `features/INDEX.md` | Feature-Übersicht |
