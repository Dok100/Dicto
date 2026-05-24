# PROJ-28 – Ollama Streaming

## Ziel

Ollama-Antworten erscheinen live Wort für Wort im Panel statt erst nach vollständiger
Verarbeitung. Besonders bei großen Modellen (qwen2.5:32b) reduziert das die gefühlte
Wartezeit erheblich.

## Verhalten

- Panel öffnet sich sofort wenn Ollama beginnt zu antworten (nicht erst am Ende)
- Text wächst live mit blinkendem `▍`-Cursor
- Während auf den **ersten Token** gewartet wird (Time to First Token): pulsierende
  Punkte + „Warte auf Antwort …" – kein leeres Panel mehr
- Nach abgeschlossenem Streaming: normaler Übergang zu `.done` (Vorschau oder Auto-Paste)

## Neuer State

```swift
case streaming(String)   // in TranscriptionState
```

Wird sowohl von Ollama (nach Aufnahme) als auch von Apple Speech (während Aufnahme) genutzt.

## Implementierung

**`OllamaPostProcessor` / `OllamaTransformProcessor`**
- `"stream": true` im Request-Body
- `URLSession.shared.bytes(for:)` → `asyncBytes.lines` → NDJSON-Zeilenweise dekodieren
- Jede Zeile ist ein `OllamaStreamChunk { message: { content }, done }` 
- `AsyncThrowingStream<String, Error>` liefert Chunks an AppState

**`AppState`**
- `handleTranscriptionDone`: iteriert über `streamProcess()`, akkumuliert Chunks,
  setzt `transcriptionState = .streaming(accumulated)` nach jedem Chunk
- `handleTransformDone`: analog

**`MenuBarController`**
- Panel öffnet sich auch bei `.streaming` (nicht nur bei `.done`)

**`PopoverRootView` – `StreamingTextView`**
- Leerer Zustand: drei pulsierende Punkte (Akzentfarbe) + Label
- Text-Zustand: `ScrollViewReader` scrollt automatisch nach unten, blinkender Cursor

## Gleichzeitig: Large v3 Turbo

Neues Whisper-Modell `openai_whisper-large-v3_turbo_954MB` (~950 MB) als dritte Option:
- ca. 2–3× schneller als Large v3
- Qualität nahezu identisch
- Korrekter vollständiger HuggingFace-Bezeichner nötig (kein Kurzname verfügbar)
