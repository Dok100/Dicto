# PROJ-17 – UI-Polishing

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Panel und Menübar-Icon von „funktional" auf „polished" heben –
visuell auf Augenhöhe mit nativen macOS-Menübar-Tools (Raycast, Bartender etc.).

## Umfang

| Level | Beschreibung | Status |
|-------|-------------|--------|
| A – Foundation | Frosted-Glass-Panel + State-Animationen | ✅ Abgeschlossen |
| B – Recording WOW | Pulsierende Aufnahme-Animation | ✅ Abgeschlossen |
| C – Settings Overhaul | GroupBox-Sektionen, Form-Layout | ✅ Abgeschlossen |

## Umgesetzte Änderungen (Level A)

### MenuBarController.swift
- `NSPanel`: `isOpaque = false`, `backgroundColor = .clear`, `.fullSizeContentView`,
  `titlebarAppearsTransparent = true`, `closeButton` ausgeblendet
- `minSize` auf 320×400 – verhindert zu kleines Panel auch bei altem gespeichertem Frame
- Panel-Default: 340×420 px

### PopoverRootView.swift
- `.regularMaterial` als Hintergrund → Frosted-Glass-Effekt
- **Header**: Mic-Icon in Kreis mit pulsierendem Hintergrund bei Aufnahme,
  Status-Label mit sanfter `contentTransition`
- **State-Übergänge**: `.spring(response: 0.28)` + `.opacity + scale(0.97)`
  via `stateTag`-ID-Trick – kein hartes Springen mehr zwischen Zuständen
- **Idle-View**: Shortcut-Tabelle mit Key-Badge-Styling (monospaced, `.quaternary`-Hintergrund)
- **History**: `ContentUnavailableView` wenn leer, Card-Design mit `RoundedRectangle`
- **TextEditor**: `.scrollContentBackground(.hidden)` + `.quinary`-Hintergrund
- **Footer**: `footerButton()`-Helper, kompakter Stil-Picker, Power-Icon statt Text
- **PermissionHint**: `lock.shield`-Icon, zentriert im Bereich

### Assets.xcassets (Menübar-Icons)
- `MenuBar-idle.imageset` – Template-PNG, 1×/2×/3×
- `MenuBar-recording.imageset` – Template-PNG, 1×/2×/3×
- `MenuBar-transcribing.imageset` – Template-PNG, 1×/2×/3×
- Zustandslogik: recording/transform → recording, loadingModel/transcribing → transcribing, sonst → idle

### Assets.xcassets (App-Icon)
- `AppIcon.appiconset`: Aperture-D Designer-Icons (10 Größen, 16–512@2x)
  ersetzt vorheriges Mikrofon-Icon

## Umgesetzte Änderungen (Level B)

### PopoverRootView.swift – RecordingRingsView
- 3 konzentrische Ringe, bei Aufnahme nach außen pulsierend
- Rot (Diktat) / Lila (Transform) per `isTransformRecording`
- `.easeOut(duration: 1.6).repeatForever(autoreverses: false)` + staggered `.delay(Double(i) * 0.52)`
- `onAppear` mit 50 ms Verzögerung für sauberen Animationsstart nach `.id()`-Wechsel

### PopoverRootView.swift – TranscribingDotsView
- 3 Punkte mit Up/Down-Bounce beim Transkribieren
- `.easeInOut(duration: 0.42).repeatForever(autoreverses: true)` + `.delay(Double(i) * 0.14)`

## Umgesetzte Änderungen (Level C)

### SettingsView.swift
- Komplett neu mit `Form` + `.formStyle(.grouped)` (macOS 14-Style wie Systemeinstellungen)
- 5 Sektionen: Allgemein / Sprache & Modell / Verhalten / KI-Verarbeitung / Wörterbuch
- `LabeledContent` für Ollama-Felder (Modell, Endpoint)
- `.task(id: settings.ollamaEnabled)` direkt auf dem Toggle-HStack
- Ollama-Systemprompt: `TextEditor` mit `.scrollContentBackground(.hidden)` + `.quinary`-Hintergrund
- Wörterbuch-Einträge als `ForEach` in `Section` (Form rendert als native Rows)
- Frame: `minWidth: 420, minHeight: 480`

### PopoverRootView.swift – Shortcut-Badges + Footer-Fix
- `shortcutRow(keys: [String], ...)` – jede Taste als eigenes Badge mit `+`-Trenner
- Stil-Picker in eigene Zeile zwischen Content und Footer verschoben (volle Breite)
- Footer auf 3 Icon-Buttons reduziert: gear | clock | Spacer | power
- `positionPanel`: Y-Clamping `y = max(y, visible.minY)` verhindert Panel unterhalb Dock
