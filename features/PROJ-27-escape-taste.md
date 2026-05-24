# PROJ-27 – Escape-Taste zum Schließen

## Ziel

`⎋` soll das Panel kontextabhängig schließen – ohne Maus.

## Verhalten

| Zustand | Aktion |
|---------|--------|
| Ergebnis angezeigt (`.done`) | Vorschau verwerfen → Idle |
| Fehler angezeigt (`.error`) | Fehlermeldung schließen → Idle |
| Idle / Aufnahme läuft | Panel ausblenden |

## Implementierung

Da das Panel ein `NSPanel` mit `.nonactivatingPanel`-Maske ist, empfängt SwiftUI
keine Tastatur-Events über `.keyboardShortcut()`, solange Dicto nicht die aktive App ist.
Lösung: globaler `NSEvent`-Monitor – identisches Muster wie bei `⌘+Return` (PROJ-20).

**`MenuBarController`**
- Neue Property `private weak var appState: AppState?` (weak, da `AppState` den Controller nie besitzt)
- `escapeMonitor` wird in `showPanel()` registriert und in `hidePanel()` entfernt
- Keycode 53 = Escape, keine Modifier

**`PopoverRootView`**
- Shortcut-Zeile `⎋ Schließen` in der Idle-Ansicht ergänzt

## Gleichzeitig umgesetzte Code-Qualität

- `OllamaPostProcessor.init` und `OllamaTransformProcessor.init` sind jetzt `throws` – ungültige Base-URL wirft `DictoError.ollamaNotReachable` statt Crash (kein Force-Unwrap mehr)
- `AISettingsView`: Endpoint-TextField zeigt Warnhinweis wenn URL kein `http://`/`https://`-Schema hat
