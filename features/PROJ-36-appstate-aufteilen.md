# PROJ-36 – AppState aufteilen

**Status:** Offen  
**Aufwand:** L (1–2 Tage)  
**Typ:** Refactoring

## Problem

`AppState` ist ein God Object. Es enthält:

- Recording-Steuerung (start/stop, isRecording, isTransformRecording)
- Transkriptions-Koordination (WhisperService, Apple Speech)
- Post-Processing (Ollama/OpenAI-Routing, streaming)
- Text-Einfügung (confirmPaste, Pasteboard)
- Permission-Checks (Accessibility, Mikrofon, Input Monitoring)
- History (historyService)
- UI-Callbacks (onOpenSettings, onOpenHelp)
- Wörterbuch-Integration

Das macht `AppState` schwer verständlich, schwer testbar und riskant zum Ändern —
eine Änderung an einer Stelle kann unbeabsichtigt eine andere betreffen.

## Ziel

Aufteilung in fokussierte Services:

```
AppState (thin coordinator, @MainActor ObservableObject)
├── RecordingService       – Fn-Hotkey, Audio-Aufnahme, Start/Stop
├── TranscriptionService   – WhisperKit + Apple Speech, Model-Loading
├── PostProcessingService  – LLM-Routing, Streaming
├── TextInsertionService   – Pasteboard, CGEvent, confirmPaste
└── PermissionService      – Accessibility, Mikrofon, recheckPermissions
```

`AppState` hält diese Services und exponiert nur die für die UI relevanten
`@Published`-Properties (transcriptionState, isRecording etc.).

## Reihenfolge

1. `PermissionService` extrahieren (am wenigsten Abhängigkeiten)
2. `TextInsertionService` extrahieren
3. `PostProcessingService` extrahieren (nutzt PROJ-34)
4. `RecordingService` + `TranscriptionService` extrahieren (engste Kopplung, zuletzt)

## Vorbedingungen

- PROJ-34 (LLMProcessorFactory) sollte vorher abgeschlossen sein
- PROJ-35 (Provider-Konsolidierung) sollte vorher abgeschlossen sein

## Risiko

Hoch — zentralste Datei der App. Schrittweise vorgehen, nach jedem Schritt
vollständig testen. Kein "Big Bang"-Refactoring.
