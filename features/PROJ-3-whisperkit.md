# PROJ-3 – WhisperKit-Transkription

## Ziel

Nach dem Loslassen der Fn-Taste wird die aufgenommene WAV-Datei automatisch
transkribiert. Das Ergebnis steht als `String` bereit – für PROJ-4 (Text-Einfügung).
Der Popover zeigt Lade- und Transkriptions-Fortschritt an.

## Scope

- WhisperKit als Swift Package in `project.yml` einbinden
- `WhisperService`: lädt Modell beim ersten Start, transkribiert WAV → String
- `TranscriptionState`-Enum: `.idle` / `.loadingModel(Double)` / `.transcribing` / `.done(String)` / `.error(String)`
- `AppState` startet Transkription automatisch nach `onKeyUp`
- `PopoverRootView` zeigt Fortschritts- und Ergebnis-Anzeige
- Modell-Zielordner: WhisperKit-Standard (`~/Library/Caches/huggingface/…`)

## Out-of-Scope

- Text-Einfügung (PROJ-4)
- Post-Processor / Ollama-Glättung (PROJ-5/6)
- Modell-Auswahl in der UI (PROJ-7)

## Akzeptanzkriterien

- [ ] `make generate && make build` grün (WhisperKit als SPM-Dependency)
- [ ] Erster App-Start: Modell wird heruntergeladen, Fortschritt sichtbar im Popover
- [ ] Fn halten → sprechen → loslassen → Transkription erscheint im Popover
- [ ] Transkription ist auf Deutsch (`language: "de"`)
- [ ] Bei Fehler (Modell nicht geladen, Datei fehlt): Fehlermeldung im Popover, kein Absturz

## Dateistruktur

```
Sources/App/
  Models/
    AppState.swift            # erweitert: startet Transkription nach onKeyUp
    TranscriptionState.swift  # Enum für Transkriptions-Zustand
  Services/
    WhisperService.swift      # WhisperKit-Wrapper
  Views/
    PopoverRootView.swift     # erweitert: zeigt Transkriptions-Status
```

## Umsetzungsnotizen

### WhisperKit SPM-Integration in project.yml

```yaml
packages:
  WhisperKit:
    url: https://github.com/argmaxinc/WhisperKit
    from: "0.9.0"

targets:
  Dicto:
    dependencies:
      - package: WhisperKit
        product: WhisperKit
```

### WhisperService

WhisperKit ist vollständig `async/await`-basiert – das ist Swifts modernes
Concurrency-Modell. Ein `async func` kann man nicht direkt aus einem normalen
Closure aufrufen; dafür wrappen wir den Aufruf in `Task { }` (startet eine
neue asynchrone Aufgabe auf dem Swift Concurrency Thread-Pool).

```swift
// Vereinfachte Struktur:
final class WhisperService: ObservableObject {
    @Published private(set) var state: TranscriptionState = .idle
    private var whisperKit: WhisperKit?

    func loadModelIfNeeded() async { … }
    func transcribe(fileURL: URL) async -> String { … }
}
```

`@Published` + `ObservableObject`: SwiftUI beobachtet `state` automatisch
und zeichnet den Popover neu sobald sich der Wert ändert – genau wie bei
`AppState.isRecording`.

Wichtig: `@Published`-Werte dürfen nur auf dem **Main Thread** gesetzt werden.
Da WhisperKit-Callbacks auf Background-Threads laufen, nutzen wir
`await MainActor.run { self.state = … }`.

### Modell-Download

WhisperKit lädt das Modell bei der ersten `WhisperKit(model:)` Initialisierung
herunter und cached es lokal. Download-Fortschritt kommt über einen
`Progress`-Callback. Wir mappen das auf `TranscriptionState.loadingModel(Double)`.

Modell: `openai_whisper-large-v3-turbo` – gute Balance Qualität/Geschwindigkeit.
Größe: ~600 MB, einmaliger Download.

### AppState-Änderung

`onKeyUp`-Closure erhält die WAV-URL von `stopRecording()` und startet
die Transkription via `Task { }`:

```swift
hotkey.onKeyUp = { [weak self] in
    guard let self else { return }
    self.isRecording = false
    if let url = audio.stopRecording() {
        Task { await self.whisperService.transcribe(fileURL: url) }
    }
}
```

### Popover-Erweiterung

Neuer Status-Bereich unterhalb des Mic-Icons:
- `.loadingModel(0.45)` → ProgressView + "Modell wird geladen… 45%"
- `.transcribing` → ProgressView (indeterminate) + "Transkribiere…"
- `.done("Hallo Welt")` → Text in einem scrollbaren Label
- `.error(msg)` → rote Fehlermeldung

## Status

In Arbeit – Feature-Dokument zur Review, wartet auf Freigabe für Swift-Code.
