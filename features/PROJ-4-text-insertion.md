# PROJ-4 – Text-Einfügung via Pasteboard

## Ziel

Den transkribierten Text automatisch an die aktuelle Cursor-Position einfügen,
sobald die Transkription abgeschlossen ist. Kein manuelles Kopieren nötig.

## Ablauf

```
Transkription .done(text)
    → alten Clipboard-Inhalt sichern
    → text in NSPasteboard schreiben
    → Cmd+V simulieren (CGEvent)
    → alten Clipboard-Inhalt wiederherstellen
```

## Technische Umsetzung

### PasteService (neuer Service)

```swift
final class PasteService {
    func paste(text: String) async { ... }
}
```

1. **NSPasteboard**: `NSPasteboard.general` – schreibt String, liest alten Inhalt
2. **CGEvent Cmd+V**: Simuliert Tastendruck in der zuletzt aktiven App
3. **Accessibility-Permission**: `AXIsProcessTrusted()` – nötig für CGEvent-Simulation

### CGEvent-Simulation (Cmd+V)

```swift
let src = CGEventSource(stateID: .hidSystemState)
let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
keyDown?.flags = .maskCommand
keyDown?.post(tap: .cgAnnotatedSessionEventTap)
// keyUp analog
```

`virtualKey 0x09` = V-Taste (kVK_ANSI_V).

### Clipboard-Restore

NSPasteboard hat keine direkte "push/pop"-API. Wir lesen den alten String-Inhalt
vor dem Schreiben und schreiben ihn danach wieder zurück.
Limitation: andere Datentypen (Bilder, RTF) gehen verloren – akzeptierter Trade-off.

## Berechtigungen

| Permission | Wozu | System Preferences |
|---|---|---|
| Accessibility (Barrierefreiheit) | CGEvent-Simulation | Privacy_Accessibility |

Ohne Permission: Text landet zwar in der Zwischenablage, wird aber nicht eingefügt.
→ PermissionHint im Popover wie bei Input Monitoring / Mikrofon.

## AppState-Integration

`AppState` ruft `PasteService.paste(text:)` auf, sobald `transcriptionState == .done(text)`.
Bestehender Combine-Subscriber in `MenuBarController` öffnet schon den Popover –
der `PasteService`-Aufruf kommt zusätzlich in `AppState`.

## Dateien

| Datei | Änderung |
|---|---|
| `Sources/App/Services/PasteService.swift` | Neu |
| `Sources/App/Models/AppState.swift` | PasteService integrieren |
| `Sources/App/Views/PopoverRootView.swift` | Accessibility-PermissionHint |
| `Sources/App/Models/AppState.swift` | missingPermission um `.accessibility` erweitern |

## Akzeptanzkriterien

- [ ] Fn halten → sprechen → loslassen → Text erscheint an Cursor-Position
- [ ] Alter Clipboard-Inhalt bleibt nach Paste erhalten
- [ ] Fehlender Accessibility-Zugriff zeigt Hinweis im Popover
- [ ] Kein Crash wenn Popover im Vordergrund ist (kein Fokus auf externer App)

## Status

In Arbeit
