# Dicto – Architektur

## Übersicht

```
┌─────────────────────────────────────────────────────────────┐
│  macOS                                                       │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │ HotkeyService│───▶│ AudioService │───▶│WhisperService │  │
│  │ (CGEventTap) │    │(AVAudioRec.) │    │ (WhisperKit)  │  │
│  └──────────────┘    └──────────────┘    └───────┬───────┘  │
│                                                   │          │
│                                          ┌────────▼───────┐  │
│                                          │ PostProcessor  │  │
│                                          │ (Protokoll)    │  │
│                                          └────────┬───────┘  │
│                                                   │          │
│                                          ┌────────▼───────┐  │
│                                          │PasteboardService│ │
│                                          │(NSPasteboard + │  │
│                                          │ Cmd+V Sim.)    │  │
│                                          └───────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ MenuBarController  (NSStatusItem + NSPopover)        │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Komponenten

### HotkeyService
- Globaler `CGEventTap` auf `flagsChanged`-Events
- Erkennt Fn-Taste über `NX_DEVICELSHIFTKEYMASK`-Kombination (Plan B: rechte Ctrl-Taste)
- Publiziert `isRecording: Bool` via Combine / `@Published`
- **Fallstrick**: CGEventTap benötigt Accessibility-Berechtigung (systemweite Nutzerfreigabe, kein Entitlement). App muss in Systemeinstellungen → Datenschutz → Bedienungshilfen freigeschaltet werden.

### AudioService
- `AVAudioRecorder`, 16 kHz, Mono, WAV
- Aufnahme-Zielordner: `~/Library/Caches/Dicto/`
- Startet/stoppt synchron mit HotkeyService-Signal

### WhisperService
- Wrapper um WhisperKit
- Modell: `openai_whisper-large-v3-turbo`
- Sprache: `de` (fest)
- Modell-Download beim ersten Start mit Fortschrittsanzeige im Popover
- Läuft in `Task { }` (Swift Concurrency), blockiert nicht den Main Thread

### PostProcessor (Protokoll)
```swift
protocol TextPostProcessor {
    func process(_ text: String) async -> String
}
```
- `PassthroughPostProcessor`: gibt Text unverändert zurück
- `OllamaPostProcessor`: sendet Text an `http://localhost:11434`, Fallback auf Passthrough bei Fehler

### PasteboardService
- Sichert aktuellen Pasteboard-Inhalt
- Setzt transkribierten Text
- Simuliert Cmd+V via `CGEvent`
- Stellt Original nach 0.5 s wieder her

### MenuBarController
- `NSStatusItem` mit eigenem Icon (SF Symbol `mic.fill` als Fallback)
- `NSPopover` mit `PopoverRootView` (SwiftUI)
- Status-Anzeigen: Idle / Aufnahme / Transkription / Fehler

## Datenfluss

```
Fn↓ → HotkeyService → AudioService.start()
Fn↑ → HotkeyService → AudioService.stop() → WAV-Datei
                     → WhisperService.transcribe(wav) → String
                     → PostProcessor.process(String) → String
                     → PasteboardService.insert(String)
```

## Technische Entscheidungen

Siehe [decision-log.md](decision-log.md).

## Abhängigkeiten

| Abhängigkeit | Version | Zweck |
|---|---|---|
| WhisperKit | aktuell (main) | Lokale ASR |
| Ollama | lokal | Text-Glättung (optional) |
| XcodeGen | via Homebrew | Projekt-Generator |
| swiftformat | via Homebrew | Code-Formatierung |

## Berechtigungen

| Berechtigung | Art | Grund |
|---|---|---|
| Mikrofon | Entitlement + Usage Description | Audio-Aufnahme |
| Bedienungshilfen | Systemweite Nutzerfreigabe | CGEventTap für globalen Hotkey |
| Input Monitoring | Systemweite Nutzerfreigabe | Fn-Taste als globaler Hotkey |

App-Sandbox ist **deaktiviert** (ENABLE_APP_SANDBOX=NO), da CGEventTap und Cmd+V-Simulation Sandbox-Grenzen sprengen.
