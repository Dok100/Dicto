# PROJ-26 – Eigene Stile konfigurieren

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Nutzer können in den Einstellungen eigene Diktat-Stile mit beliebigen System-Prompts anlegen, benennen, bearbeiten und löschen. Diese erscheinen im Panel unterhalb der festen Stile als auswählbare Chips.

## Verhalten

- Eigene Stile erscheinen im Panel in einer **eigenen Zeile unterhalb** des festen Pickers
- Chip-Auswahl: blauer Hintergrund = aktiv; Klick auf festen Stil → Chip wird abgewählt
- Eigene Stile verwenden **immer Ollama** (unabhängig vom Ollama-Toggle) – bei deaktiviertem Ollama erscheint eine orangene Warnung
- Kein Neustart nötig: Stile sind sofort nach dem Speichern im Panel sichtbar

## Beispiel-Anwendungsfall

**„Signal – Empathisch"**: Prompt der eine spontane gesprochene Reaktion in eine herzliche, persönliche Nachricht umwandelt.

## Umgesetzte Änderungen

### CustomStyle.swift (neu)
- `public struct CustomStyle: Codable, Identifiable, Equatable`
- Felder: `id: UUID`, `name: String`, `prompt: String`

### AppSettings.swift
- `customStyles: [CustomStyle]` – JSON-kodiert in UserDefaults (`customStyles`)

### AppState.swift
- `@Published private(set) var selectedCustomStyle: CustomStyle?`
- `func selectFixedStyle(_ style: DictationStyle)` – setzt festen Stil, löscht Custom-Auswahl
- `func selectCustomStyle(_ style: CustomStyle)` – wählt eigenen Stil
- `handleTranscriptionDone`: nutzt `selectedCustomStyle.prompt` wenn gesetzt, sonst festen Stil-Prompt
- `settings.objectWillChange.sink { self?.objectWillChange.send() }` – leitet Settings-Änderungen weiter, damit Panel neu rendert
- Stats: `styleName = selectedCustomStyle?.name ?? dictationStyle.rawValue`

### PopoverRootView.swift
- `stylePicker`: neues `@ViewBuilder`-Property mit festen Stilen + Custom-Zeile
- `customStylesRow`: horizontaler ScrollView mit `CustomStyleChipStyle`-Buttons
- `ollamaWarning()`: wiederverwendbare `@ViewBuilder`-Funktion für orange Warnzeile
- `mainContent` + `previewActionsSection`: aus `body` extrahiert (Compiler-Komplexität)
- `CustomStyleChipStyle: ButtonStyle` – Pill-Button, blau wenn ausgewählt

### AISettingsView.swift
- Neue Sektion „Eigene Stile" mit Liste + Bleistift/Papierkorb pro Eintrag
- `CustomStyleEditView`: Sheet mit `TextField` (Name) + `TextEditor` (Prompt)
- Footer-Hinweis: „Eigene Stile erscheinen im Panel unterhalb der festen Stile und verwenden immer Ollama."

## Bekannte Fallstricke

- **`settings.objectWillChange`-Forwarding**: `PopoverRootView` beobachtet nur `AppState`. Ohne das Forwarding in `AppState.init()` würden neue/geänderte Custom-Stile nicht im Panel erscheinen.
- **Swift-Compiler Komplexität**: Zu viel Logik in einem `body`-Block führt zu „unable to type-check"-Fehlern → in separate `@ViewBuilder`-Properties extrahieren.
- **Struct-Scope-Fehler**: Neue Properties müssen physisch VOR der schließenden `}` des jeweiligen Structs stehen – besonders wenn Hilfstructs (RecordingRingsView, PermissionHint) in derselben Datei folgen.

## Testen

1. Einstellungen → KI → „Stil hinzufügen" → Name + Prompt eingeben → Speichern
2. Panel öffnen → neuer Chip erscheint unterhalb der festen Stile
3. Chip klicken → blau markiert → Diktat nutzt diesen Prompt
4. Festen Stil klicken → Chip wird abgewählt
5. Stil bearbeiten (Bleistift) → Änderungen sofort wirksam
6. Stil löschen (Papierkorb) → Chip verschwindet aus Panel
7. App neu starten → eigene Stile bleiben erhalten
