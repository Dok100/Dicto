# PROJ-20 – Konfigurierbarer Tastatur-Shortcut

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Diktat- und Transform-Shortcut im Einstellungsfenster frei konfigurierbar machen.
Standard bleibt Fn / ⌥+Fn; Nutzer können auf beliebige Kombinationen umstellen.

## Unterstützte Shortcut-Typen

| Typ | Mechanismus | Beispiele |
|-----|------------|---------|
| Fn-basiert | `flagsChanged`-Event, keyCode 63 | Fn, ⌥+Fn, ⌃+Fn |
| Normale Taste | `keyDown`/`keyUp`-Event | ⌘+D, ⌃+Space, ⌘+⇧+R |

Normale Tasten erfordern mindestens einen Modifier (⌘ ⌥ ⌃ ⇧) um versehentliches Auslösen zu verhindern.

## Umgesetzte Änderungen

### ShortcutConfig.swift (neu)
- `isFlagsBased: Bool` – Typ des Shortcuts
- `keyCode: UInt16` – Taste
- `modifierRaw: UInt` – `NSEvent.ModifierFlags` als gespeicherte Zahl
- `modifierFlags: NSEvent.ModifierFlags` – berechnete Property (deviceIndependentFlagsMask)
- `displayKeys: [String]` – Badge-Anzeige, z.B. `["⌥", "Fn"]` oder `["⌘", "D"]`
- `keyCodeNames` – Lookup-Tabelle für 60+ Tasten (Buchstaben, Sondertasten, Pfeile, F-Tasten)
- `defaultDictation` = Fn allein
- `defaultTransform` = ⌥+Fn

### AppSettings.swift
- `dictationShortcut: ShortcutConfig` – JSON-kodiert in UserDefaults (`dictationShortcut`)
- `transformShortcut: ShortcutConfig` – JSON-kodiert in UserDefaults (`transformShortcut`)

### HotkeyService.swift (Neufassung)
- `dictationShortcut` / `transformShortcut` mit `didSet { reinstallMonitors() }`
- Zwei Monitor-Gruppen: `flagsChanged` (immer) + `keyDown`/`keyUp` (für reguläre Shortcuts)
- `handleFlagsChanged`: Fn-Taste → Transform zuerst prüfen (spezifischer), dann Diktat
- `handleKeyDown` / `handleKeyUp`: reguläre Taste → gleiche Priorität
- `fnModifiersMatch()`: vergleicht konfigurierte Modifier mit Event-Modifiern exakt
- `activeMode: .none / .dictation / .transform` verhindert Doppelauslösung

### AppState.swift
- `HotkeyService` wird mit `settings.dictationShortcut` / `settings.transformShortcut` initialisiert
- Combine: `settings.$dictationShortcut` / `settings.$transformShortcut` → `hotkeyService` aktualisieren

### ShortcutRecorderView.swift (neu)
- Zeigt aktuelle Kombination als Badges (identisches Styling wie Panel)
- "Ändern"-Button → Aufzeichnungs-Modus
- Lokaler `NSEvent`-Monitor für `flagsChanged` + `keyDown`
- Fn: erste `flagsChanged` mit function-Flag → gespeichert
- Normale Taste: `keyDown` + mindestens ein Modifier → gespeichert
- Escape → Abbrechen
- Keine Modifier bei normaler Taste → visueller Shake-Effekt

### GeneralSettingsView.swift
- Neue Sektion "Tastaturkürzel" mit zwei `ShortcutRecorderView`-Zeilen
- "Auf Standard zurücksetzen"-Button

## Testen

1. Einstellungen → Allgemein → Tastaturkürzel
2. "Ändern" klicken → "Taste drücken…" erscheint
3. Fn drücken → speichert Fn; ⌥+Fn → speichert ⌥+Fn; ⌘+D → speichert ⌘+D
4. App neu starten → Einstellung bleibt erhalten
5. "Auf Standard zurücksetzen" → stellt Fn / ⌥+Fn wieder her
