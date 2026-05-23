# PROJ-17 – UI-Polishing

**Status**: In Bearbeitung
**Branch**: main

## Ziel

Panel und Menübar-Icon von „funktional" auf „polished" heben –
visuell auf Augenhöhe mit nativen macOS-Menübar-Tools (Raycast, Bartender etc.).

## Umfang

| Level | Beschreibung | Status |
|-------|-------------|--------|
| A – Foundation | Frosted-Glass-Panel + State-Animationen | ✅ Abgeschlossen |
| B – Recording WOW | Pulsierende Aufnahme-Animation | ✅ Abgeschlossen |
| C – Settings Overhaul | GroupBox-Sektionen, Form-Layout | Offen |

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

## Offene Punkte (Level B + C)

### Level B – Recording WOW
- Konzentrische Ringe die bei Aufnahme nach außen pulsieren
- Lila Partikel-Animation bei Transform-Aufnahme
- Elegante Punkte-Animation statt Standard-Spinner beim Transkribieren

### Level C – Settings Overhaul
- `Form` + `Section` für logische Gruppen (Allgemein / Modell / Verarbeitung / Wörterbuch)
- Jede Sektion als `GroupBox` mit Header-Styling
- Konsistente Einzüge und Abstände
