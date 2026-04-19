# PROJ-2 – Globaler Fn-Hotkey + Audio-Aufnahme

## Ziel

Fn-Taste gedrückt halten startet die Aufnahme, loslassen stoppt sie. Das aufgenommene Audio wird als WAV-Datei gespeichert und steht für PROJ-3 (WhisperKit) bereit. Der Popover zeigt den aktuellen Zustand an (Idle / Aufnahme läuft).

## Scope

- `HotkeyService`: globaler `CGEventTap` auf `flagsChanged`, erkennt Fn-Taste (Keydown/Keyup)
- `AudioService`: `AVAudioRecorder`, 16 kHz, Mono, WAV → `~/Library/Caches/Dicto/recording.wav`
- `AppState`: einfaches `ObservableObject` mit `@Published var isRecording: Bool`, verbindet HotkeyService → AudioService → Popover-UI
- `PopoverRootView` zeigt Status-Indikator (Idle-Icon / roter Punkt bei Aufnahme)
- Berechtigungs-Hinweis im Popover, falls Accessibility-Permission fehlt

## Out-of-Scope

- Transkription (kommt in PROJ-3)
- Text-Einfügung (kommt in PROJ-4)
- Einstellungen für Hotkey-Wahl (kommt in PROJ-7)

## Akzeptanzkriterien

- [ ] Fn-Taste gedrückt → Aufnahme startet (Mikrofon-Aktivität sichtbar)
- [ ] Fn-Taste losgelassen → Aufnahme stoppt, WAV-Datei liegt unter `~/Library/Caches/Dicto/recording.wav`
- [ ] Popover-Icon wechselt während Aufnahme auf roten Punkt
- [ ] Ohne Accessibility-Berechtigung: Hinweis im Popover, kein Absturz
- [ ] `make build` grün, keine Compiler-Warnings

## Umsetzungsnotizen

### Dateistruktur

```
Sources/App/
  Models/
    AppState.swift              # @Published isRecording, hält Services
  Services/
    HotkeyService.swift         # CGEventTap, Fn-Erkennung
    AudioService.swift          # AVAudioRecorder-Wrapper
  Views/
    PopoverRootView.swift       # erweitert um Status-Anzeige
```

### HotkeyService – CGEventTap und Fn-Taste

**Eigenheit**: `CGEventTap` erfordert Accessibility-Berechtigung (Systemeinstellungen → Datenschutz → Bedienungshilfen). Ohne sie liefert `CGEvent.tapCreate` `nil` – kein Absturz, aber auch kein Hotkey. Die App muss das erkennen und im Popover darauf hinweisen.

**Fn-Erkennung**: Fn erzeugt kein normales `keyDown`-Event, sondern ein `flagsChanged`-Event. Erkannt wird sie über das Flags-Bit `NX_SECONDARYFNMASK` (Wert `0x800000`) in `CGEventFlags`. Keydown = Flag gesetzt, Keyup = Flag weg.

**Swift Concurrency-Eigenheit**: Der CGEventTap-Callback ist eine C-Callback-Funktion, kein Swift-async-Code. Wir nutzen `DispatchQueue.main.async` um von der Callback-Welt in den Main Thread zu wechseln, wo `@Published`-Properties aktualisiert werden dürfen.

**Plan B**: Rechte Ctrl-Taste – `keyDown`/`keyUp` mit `keyCode 0x3E`. Umstellbar per Konstante in `HotkeyService`.

### AudioService – AVAudioRecorder

- Format: `kAudioFormatLinearPCM`, 16 kHz, 1 Kanal, 16 Bit
- Zielordner: `~/Library/Caches/Dicto/` wird beim ersten Start angelegt
- Dateiname: `recording.wav` (wird bei jeder neuen Aufnahme überschrieben)
- `AVAudioSession` ist auf macOS nicht nötig (nur iOS/iPadOS)

### AppState

`AppState` ist ein `@MainActor`-gebundenes `ObservableObject`. Es hält beide Services und leitet HotkeyService-Signale an AudioService weiter. `PopoverRootView` bekommt `AppState` als `@EnvironmentObject`.

## Status

**Abgeschlossen** – Fn/Globe-Taste erkannt via `NSEvent.addGlobalMonitorForEvents`, WAV-Aufnahme funktioniert, Datei abspielbar. Manuell getestet auf MacBook Pro M4, macOS Sequoia.

### Erkenntnisse aus der Umsetzung

- `CGEventTap` empfängt Globe-Key-Events auf M-Chip Macs unter macOS Sequoia nicht. `NSEvent.addGlobalMonitorForEvents` (Cocoa-Ebene) ist die korrekte Lösung.
- Voraussetzung: Systemeinstellungen → Tastatur → 🌐-Taste → **"Keine Aktion"**
- `AVAudioRecorder` muss Mikrofon-Permission **vor** dem ersten `record()`-Aufruf haben, sonst schreibt er nur einen leeren FLLR-Header (4096 Bytes, kein Audio).
- `NSEvent.addGlobalMonitorForEvents` benötigt Input Monitoring Permission (Eingabe-Überwachung).
