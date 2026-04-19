# PROJ-6 – OllamaPostProcessor

## Ziel

Transkribierten Text via Ollama glätten: Satzzeichen einfügen, Füllwörter entfernen,
Lesbarkeit verbessern. Fällt Ollama aus, wird der Originaltext eingefügt (Fallback).

## API

```
POST http://localhost:11434/api/chat
{
  "model": "glm-4.7-flash",
  "messages": [
    { "role": "system", "content": "..." },
    { "role": "user",   "content": "<transkribierter text>" }
  ],
  "stream": false
}
```

Response: `message.content`

## Fallback-Strategie

Jeder Fehler (Timeout, Ollama nicht erreichbar, leere Antwort) → Originaltext zurückgeben.
Kein Fehler-State, kein UI-Hinweis – Nutzer bemerkt es nicht.

## AppState-Integration

`AppState.postProcessor` wird auf `OllamaPostProcessor()` gesetzt.
PROJ-7 (Einstellungen) fügt einen Toggle hinzu.

## Dateien

| Datei | Änderung |
|---|---|
| `Sources/App/PostProcessors/OllamaPostProcessor.swift` | Neu |
| `Sources/App/Models/AppState.swift` | Default auf OllamaPostProcessor |

## Akzeptanzkriterien

- [ ] Text wird durch Ollama geglättet (Satzzeichen, keine Füllwörter)
- [ ] Bei Ollama-Ausfall: Originaltext landet trotzdem im Textfeld
- [ ] Timeout nach 30 Sekunden

## Status

In Arbeit
