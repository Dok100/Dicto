# PROJ-12 – Transform-Modus (Alt+Fn)

**Status**: Abgeschlossen
**Branch**: main

## Ziel

Text in einer anderen App markieren, Alt+Fn halten, Befehl diktieren → Ollama transformiert den markierten Text gemäß dem Befehl und ersetzt ihn.

## Ablauf

1. Text in Ziel-App markieren
2. **Alt** halten, dann **Fn** dazuhalten
3. Befehl diktieren ("übersetze ins Englische", "mache formeller", …)
4. Fn loslassen → WhisperKit transkribiert → Ollama verarbeitet Original + Befehl → Ergebnis erscheint im Vorschau-Panel
5. **Kopieren** (⌘+Return) kopiert in Clipboard, **Einfügen** fügt an Cursor-Position ein (sofern Eingabehilfen freigegeben)

> Transform zeigt **immer** eine Vorschau – unabhängig von der "Vorschau vor Einfügen"-Einstellung, da Auto-Einfügen bei Transformationen keinen Sinn ergibt.

## Umgesetzte Änderungen

### HotkeyService.swift
- `onTransformKeyDown` / `onTransformKeyUp` Callbacks
- `isTransformMode: Bool` merkt sich ob aktueller Tastendruck Fn+Alt ist
- Alt muss vor Fn gedrückt werden (beim Fn-keyDown wird `.option` in modifierFlags geprüft)

### PasteService.swift
- `captureSelectedText() async -> String`: simuliert Cmd+C, liest Clipboard, stellt Original wieder her (200 ms Wartezeit)

### OllamaTransformProcessor.swift (neu)
- `process(original:command:) async -> String`
- System-Prompt: Texttransformation, nur transformierten Text zurückgeben
- User-Message: `<original>…</original>\n<befehl>…</befehl>`
- Fallback: Originaltext bei Fehler

### AppState.swift
- `@Published private(set) var isTransformMode: Bool` + `selectedTextForTransform: String?`
- `@Published private(set) var isTransformResult: Bool` – unterscheidet Transform-Ergebnis von normalem Diktat-Ergebnis in der View
- `onTransformKeyDown`: speichert targetApp, startet Aufnahme, erfasst Clipboard asynchron
- `handleTranscriptionDone`: leitet bei Transform-Modus an `handleTransformDone` weiter
- `handleTransformDone`: ruft OllamaTransformProcessor auf, setzt `isTransformResult = true`, zeigt immer Vorschau (kein Auto-Einfügen)
- `dismissResult()`: setzt `isTransformResult` und `transcriptionState` zurück auf Idle
- `confirmPaste(original:edited:)`: setzt `isTransformResult = false` nach Einfügen

### MenuBarController.swift
- Status-Dot lila (`systemPurple`) während `isTransformMode == true` (überlagert roten Diktat-Dot)

### PopoverRootView.swift
- `previewActions`: zeigt bei `isTransformResult` zwei Buttons — **Kopieren** (⌘+Return, `.borderedProminent`) + **Einfügen** (`.bordered`, deaktiviert ohne Eingabehilfen)
- Idle-Ansicht zeigt Shortcut-Übersicht: Fn, Alt+Fn, ⌘+Return, ⌘Q

## Bekannte Eigenheit: NSPanel statt NSPopover

Im gleichen Zug wurde der NSPopover durch ein NSPanel ersetzt, um Resize-Unterstützung zu ermöglichen. Kritisch dabei: `.nonactivatingPanel` + kein `makeKey()` – sonst würde Dicto zur vordersten App und `targetApp` wäre falsch gesetzt.
