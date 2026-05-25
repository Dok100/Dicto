# PROJ-38 – Fehleranzeige im Popover

## Ziel

Fehler werden dem Nutzer sichtbar und handlungsorientiert angezeigt – unabhängig davon, ob der Preview-Modus aktiv ist.

## Problem

Bisher öffnete sich das Panel bei `TranscriptionState.error` **nicht automatisch**. Der Nutzer sah nur einen Icon-Wechsel im Menübar (`exclamationmark.circle`), aber keinen Fehlertext. Außerdem speicherte `TranscriptionState.error(String)` nur einen vorformatierten String, was das String-Parsing in der View nötig machte.

## Änderungen

### 1. `TranscriptionState` – typsicher

```swift
// vorher:
case error(String)

// nachher:
case error(DictoError)
```

### 2. `DictoError` – actionable Properties

Neue Properties:
- `systemSettingsURL: URL?` – Link zu macOS-Systemeinstellungen (z. B. Spracherkennung)
- `needsAppSettings: Bool` – zeigt "Einstellungen öffnen"-Button in der App

### 3. `MenuBarController` – Auto-Open bei Fehler

```swift
case .error:
    self.showPanel()  // immer, unabhängig von previewEnabled
```

### 4. `PopoverRootView` – verbessertes `errorView`

- Kein String-Parsing mehr – direkt `DictoError.title` / `.detail`
- "Einstellungen öffnen"-Button bei Config-Fehlern (Ollama, OpenAI)
- "Systemeinstellungen öffnen" bei Permission-Fehlern (Apple Speech)
- "Schließen" bleibt immer verfügbar (auch via Escape)

## Akzeptanzkriterien

- [ ] Fehler (Ollama nicht erreichbar, Whisper-Fehler etc.) öffnen das Panel automatisch
- [ ] Fehlertext zeigt Titel + Detail aus DictoError
- [ ] Bei Ollama/OpenAI-Fehlern: Button öffnet App-Einstellungen
- [ ] Bei Speech-Permission-Fehler: Button öffnet Systemeinstellungen
- [ ] Schließen via Button oder Escape funktioniert
- [ ] Alle Tests grün

## Status

Abgeschlossen ✅
