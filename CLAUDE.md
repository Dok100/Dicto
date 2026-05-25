# CLAUDE.md – Dicto

Persistenter Kontext für Claude Code über Sessions hinweg.

## Projekt-Übersicht

Native macOS-Menübar-App für Push-to-Talk-Diktat, vollständig lokal auf Apple Silicon.
Fn-Taste → Aufnahme → WhisperKit-Transkription → Text an Cursor-Position einfügen.
Optional: Glättung via Ollama (qwen2.5:32b, http://localhost:11434).

## Aktueller Phasenstand

**Stand**: PROJ-1–PROJ-23, PROJ-26–PROJ-37 abgeschlossen.

| Phase | Status |
|-------|--------|
| PROJ-1 Menübar-App-Gerüst | Abgeschlossen |
| PROJ-2 Fn-Hotkey + Audio | Abgeschlossen |
| PROJ-3 WhisperKit | Abgeschlossen |
| PROJ-4 Text-Einfügung | Abgeschlossen |
| PROJ-5 PostProcessor-Protokoll | Abgeschlossen |
| PROJ-6 OllamaPostProcessor | Abgeschlossen |
| PROJ-7 Einstellungsfenster | Abgeschlossen |
| PROJ-8 Stil-Auswahl (Neutral/Formell/Locker/Empathisch) | Abgeschlossen |
| PROJ-9 Whisper-Modellauswahl (Base / Large v3) | Abgeschlossen |
| PROJ-10 Preview-Modus (opt-in, editierbar vor Einfügen) | Abgeschlossen |
| PROJ-11 Wörterbuch (statisch + lernend via Preview) | Abgeschlossen |
| PROJ-12 Transform-Modus (Alt+Fn: Selektion + Befehl) | Abgeschlossen |
| PROJ-13 Launch at Login (SMAppService) | Abgeschlossen |
| PROJ-14 Sprachauswahl (Deutsch / Englisch / Auto) | Abgeschlossen |
| PROJ-15 Diktat-Verlauf (letzte 20 Einträge) | Abgeschlossen |
| PROJ-16 Wörterbuch Export/Import | Abgeschlossen |
| PROJ-17 UI-Polishing | Abgeschlossen (Level A+B+C ✅) |
| PROJ-18 Onboarding / First-Run-Experience | Abgeschlossen |
| PROJ-19 Einstellungs-Tabs + Diktat-Statistiken | Abgeschlossen |
| PROJ-20 Konfigurierbarer Tastatur-Shortcut | Abgeschlossen |
| PROJ-21 Deutsch → Englisch Übersetzung (→ EN Stil) | Abgeschlossen |
| PROJ-22 Ollama Modellauswahl (Dropdown aus /api/tags) | Abgeschlossen |
| PROJ-23 Sound-Feedback (Tink/Pop bei Start/Stop) | Abgeschlossen |
| PROJ-26 Eigene Stile konfigurieren (Custom-Prompts) | Abgeschlossen |
| PROJ-27 Escape-Taste zum Schließen des Panels | Abgeschlossen |
| PROJ-28 Ollama Streaming + Whisper Large v3 Turbo | Abgeschlossen |
| PROJ-29 Apple Speech Engine (live, kein Download) | Abgeschlossen |
| PROJ-30 OpenAI API als LLM-Alternative (Keychain-sicher) | Abgeschlossen |
| PROJ-31 In-App Hilfe-Fenster (8 Abschnitte) | Abgeschlossen |
| PROJ-32 Onboarding überarbeitet (5 Schritte) | Abgeschlossen |
| PROJ-33 Storage-Konstanten (Keys als enum) | Offen |
| PROJ-34 LLMProcessorFactory | Offen |
| PROJ-35 Provider-Konsolidierung (ollamaEnabled entfernen) | Offen |
| PROJ-36 AppState aufteilen (God Object → Services) | Offen |
| PROJ-37 Unit Tests | Offen |

## Nutzer-Kontext

- Technischer Anfänger in Swift, aber erfahren mit Projekt-Struktur (hat FRITZ!Box Monitor App gebaut)
- Swift-Spezifika (Actors, Combine, async/await-Edges) kurz erläutern
- macOS-API-Fallstricke (CGEventTap, NSPasteboard, etc.) proaktiv erklären
- Hardware: MacBook Pro M4, 48 GB RAM, macOS Sequoia
- Xcode, XcodeGen, swiftformat sind installiert
- Ollama läuft lokal mit qwen2.5:32b (empfohlen) und glm4

## Projekt-Konventionen

- XcodeGen: `project.yml` ist Single Source of Truth, `.xcodeproj` wird ignoriert
- Makefile mit Targets: `install`, `generate`, `format`, `build`, `test`, `clean`
- Feature-Branches: `proj-N-slug`, Merge nach main bei Phasenabschluss
- Commit-Messages: `feat(scope): beschreibung` oder `docs: beschreibung`
- Kein App-Store, keine Sandbox, kein GitHub Actions CI

## Bekannte Fallstricke

- Accessibility-Permission: Nach XcodeGen-Regenerierung ändert sich der App-Pfad → alten Eintrag löschen, App neu starten.
- WhisperKit liefert Umlaute manchmal als NFD → DictionaryService normalisiert auf NFC vor Vergleich.
- DictationStyle.neutral → nil → verwendet editierbaren AppSettings.ollamaPrompt.

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
