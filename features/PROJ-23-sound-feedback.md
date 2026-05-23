# PROJ-23 – Sound-Feedback

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Kurze akustische Rückmeldung, wenn die Aufnahme startet und endet – so weiß man auch ohne auf den Bildschirm zu schauen, ob Dicto zuhört.

## Verhalten

| Moment | Sound | Bedeutung |
|--------|-------|-----------|
| Aufnahme startet (Fn gedrückt) | **Tink** – kurzer, heller Klick | „Ich höre zu" |
| Aufnahme endet (Fn losgelassen) | **Pop** – weiches Geräusch | „Verstanden, verarbeite…" |

Gilt für **Diktat** (Fn) und **Transform** (⌥+Fn) gleichermaßen.

## Umgesetzte Änderungen

### SoundFeedback.swift (neu)

- Einfaches `enum` mit zwei statischen Methoden
- `playStart()` → `NSSound(named: "Tink")?.play()`
- `playStop()` → `NSSound(named: "Pop")?.play()`
- Verwendet macOS-Systemsounds aus `/System/Library/Sounds/` – kein Bundle-Asset nötig

### AppSettings.swift

- `soundFeedbackEnabled: Bool` (Standard: `true`, gespeichert in UserDefaults unter `soundFeedbackEnabled`)

### AppState.swift

- Aufruf in allen 4 Closures: `onKeyDown`, `onKeyUp`, `onTransformKeyDown`, `onTransformKeyUp`
- Prüft `settings.soundFeedbackEnabled` vor jedem Aufruf

### GeneralSettingsView.swift

- Neuer Toggle „Sound-Feedback" in Sektion „Verhalten"
- Caption: „Kurzes Klicken beim Start und sanftes Pop beim Stopp der Aufnahme."

## Testen

1. Fn drücken → „Tink" zu hören
2. Fn loslassen → „Pop" zu hören
3. ⌥+Fn → gleiche Sounds auch im Transform-Modus
4. Einstellungen → Allgemein → Verhalten → „Sound-Feedback" deaktivieren → kein Sound mehr
5. App neu starten → Einstellung bleibt erhalten
