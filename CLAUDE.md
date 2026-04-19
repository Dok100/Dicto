# CLAUDE.md – Dicto

Persistenter Kontext für Claude Code über Sessions hinweg.

## Projekt-Übersicht

Native macOS-Menübar-App für Push-to-Talk-Diktat, vollständig lokal auf Apple Silicon.
Fn-Taste → Aufnahme → WhisperKit-Transkription → Text an Cursor-Position einfügen.
Optional: Glättung via Ollama (glm-4.7-flash, http://localhost:11434).

## Aktueller Phasenstand

**Aktive Phase**: PROJ-1 – Menübar-App-Gerüst
**Stand**: Phase A (Dokumentation + Gerüst) abgeschlossen. Wartet auf Review-Freigabe für Phase B (Swift-Code).

| Phase | Status |
|-------|--------|
| PROJ-1 Menübar-App-Gerüst | Phase A fertig, Phase B ausstehend |
| PROJ-2 Fn-Hotkey + Audio | Offen |
| PROJ-3 WhisperKit | Offen |
| PROJ-4 Text-Einfügung | Offen |
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

- Fn-Taste via CGEventTap: Genaue Erkennung muss in PROJ-2 empirisch validiert werden (nicht offiziell dokumentiert). Plan B: rechte Ctrl-Taste.
- WhisperKit SPM-Integration: muss in project.yml als Swift Package hinzugefügt werden (PROJ-3)

## Stack-Versionen

- Swift 5.10
- macOS 14.0+ Deployment Target
- Xcode 15+
- WhisperKit: aktuell (main branch, SPM)
- Ollama: lokal, glm-4.7-flash

## Wichtige Dateipfade

| Datei | Zweck |
|-------|-------|
| `project.yml` | XcodeGen-Konfiguration |
| `Makefile` | Build-Targets |
| `Sources/App/` | Swift-Quellcode |
| `tests/AppTests/` | Unit-Tests |
| `docs/decision-log.md` | Architekturentscheidungen |
| `features/INDEX.md` | Feature-Übersicht |
