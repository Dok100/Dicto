# Dicto — Icon Set (Aperture D)

## Inhalt

```
icon-set/
├── AppIcon.iconset/               ← Dock-/Finder-Icon (10 PNGs + Contents.json)
├── MenuBar-idle.imageset/         ← Menübar: Idle (Template, 1x/2x/3x)
├── MenuBar-recording.imageset/    ← Menübar: Aufnahme läuft
├── MenuBar-transcribing.imageset/ ← Menübar: Transkription läuft
└── preview-*.png                  ← Vorschauen für die Übersichtsseite
```

## In Xcode integrieren

### 1. App-Icon

In `Assets.xcassets` ein leeres `AppIcon`-Set ersetzen:

```bash
# .icns aus dem .iconset bauen (für Distribution außerhalb von Xcode-Assets)
iconutil -c icns icon-set/AppIcon.iconset -o Dicto.icns
```

Oder den `AppIcon.iconset`-Ordner direkt nach `Assets.xcassets/AppIcon.appiconset/`
kopieren — Xcode liest die enthaltene `Contents.json` ein.

### 2. Menübar-Icons

Die drei `.imageset`-Ordner nach `Assets.xcassets/` kopieren. In Swift:

```swift
// MenuBarController.swift
let image = NSImage(named: "MenuBar-idle")
image?.isTemplate = true   // entscheidend — macOS tintet das Bild
statusItem.button?.image = image
```

Die `Contents.json` setzt bereits `template-rendering-intent: template`, sodass
Xcode das Asset korrekt als Template-Image ausliefert.

### 3. Zustandswechsel

```swift
switch state {
case .idle:         button.image = NSImage(named: "MenuBar-idle")
case .recording:    button.image = NSImage(named: "MenuBar-recording")
case .transcribing: button.image = NSImage(named: "MenuBar-transcribing")
}
button.image?.isTemplate = true
```

## Spezifikation

| Element | Wert |
|---|---|
| App-Icon-Form | Squircle (border-radius 22,37 %) |
| Hintergrund | `#FBFAF6` (Papier) |
| Glyph | `#1A1A1C` (Tinte), Strichstärke 11 / 100 |
| Aufnahmepunkt | `#D8533B` (warmes Orange) |
| Menübar-Glyph | Schwarz auf transparent (Template) |
| Glyph-Inset App-Icon | 20 % allseitig |
| Glyph-Inset Menübar | 8 % allseitig |
