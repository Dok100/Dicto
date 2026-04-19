# PROJ-5 – TextPostProcessor-Protokoll + PassthroughPostProcessor

## Ziel

Eine austauschbare Verarbeitungsstufe zwischen Transkription und Text-Einfügung einführen.
PROJ-6 (Ollama) steckt dann einfach eine andere Implementierung ein – ohne AppState anzufassen.

## Protokoll

```swift
protocol TextPostProcessor {
    func process(text: String) async -> String
}
```

`async` damit Ollama-HTTP-Requests (PROJ-6) ohne Umbau funktionieren.

## Implementierungen

| Klasse | Verhalten |
|---|---|
| `PassthroughPostProcessor` | gibt Text unverändert zurück |
| `OllamaPostProcessor` (PROJ-6) | sendet Text an Ollama, gibt geglätteten Text zurück |

## AppState-Integration

```swift
var postProcessor: TextPostProcessor = PassthroughPostProcessor()
```

In `handleTranscriptionDone`:
```swift
let processed = await postProcessor.process(text: text)
// paste(processed) statt paste(text)
```

## Dateien

| Datei | Änderung |
|---|---|
| `Sources/App/PostProcessors/TextPostProcessor.swift` | Neu – Protokoll |
| `Sources/App/PostProcessors/PassthroughPostProcessor.swift` | Neu – Implementierung |
| `Sources/App/Models/AppState.swift` | postProcessor einbauen |

## Akzeptanzkriterien

- [ ] Protokoll kompiliert, AppState nutzt PassthroughPostProcessor
- [ ] Transkribierter Text kommt unverändert an (Verhalten identisch zu PROJ-4)
- [ ] OllamaPostProcessor kann in PROJ-6 ohne weitere AppState-Änderungen eingesteckt werden

## Status

In Arbeit
