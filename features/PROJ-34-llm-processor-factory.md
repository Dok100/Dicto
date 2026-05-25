# PROJ-34 – LLMProcessorFactory

**Status:** Offen  
**Aufwand:** M (2–3 Stunden)  
**Typ:** Refactoring

## Problem

In `AppState` wird `switch settings.llmProvider` an mindestens zwei Stellen dupliziert —
einmal für Post-Processing nach Diktat, einmal für Transform. Jedes Mal wenn ein neuer
Provider hinzukommt (z.B. Anthropic, Gemini), müssen beide Stellen angepasst werden.

```swift
// Stelle 1: handleTranscriptionDone
switch settings.llmProvider {
case .ollama:  stream = try OllamaPostProcessor(...).streamProcess(text:)
case .openAI:  stream = try OpenAIPostProcessor(...).streamProcess(text:)
}

// Stelle 2: handleTransformDone — identische Struktur
switch settings.llmProvider {
case .ollama:  stream = try OllamaTransformProcessor(...).streamProcess(text:)
case .openAI:  stream = try OpenAITransformProcessor(...).streamProcess(text:)
}
```

## Ziel

Eine `LLMProcessorFactory` kapselt die Entscheidung:

```swift
enum LLMProcessorFactory {
    static func makePostProcessor(
        settings: AppSettings,
        systemPrompt: String
    ) throws -> any TextPostProcessor

    static func makeTransformProcessor(
        settings: AppSettings,
        systemPrompt: String
    ) throws -> any TextPostProcessor
}
```

`AppState` ruft nur noch die Factory auf — kein switch mehr in der Business-Logik.

## Betroffene Dateien

- `Sources/App/Models/AppState.swift` (switch-Blöcke entfernen)
- `Sources/App/PostProcessors/LLMProcessorFactory.swift` (neu)

## Vorbedingung

PROJ-35 (Provider-Konsolidierung) sollte vorher abgeschlossen sein, damit
`ollamaEnabled` nicht mehr in der Factory berücksichtigt werden muss.

## Risiko

Mittel — Logik wird verschoben, nicht verändert. Gründliches manuelles Testen
beider Pfade (Diktat + Transform, jeweils Ollama + OpenAI) erforderlich.
