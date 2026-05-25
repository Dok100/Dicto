# PROJ-37 – Unit Tests

**Status:** Stufe 1 + 2 abgeschlossen ✅ (121 Tests)  
**Aufwand:** M–L (laufend, iterativ)  
**Typ:** Qualitätssicherung

## Problem

Aktuell gibt es keine automatisierten Tests. Jede Änderung muss manuell durch
alle Szenarien getestet werden — das dauert und führt zu Regressionen.

## Prioritäten

### Stufe 1 – Sofort sinnvoll (keine Refactorings nötig)

**DictoError**
- `fromOpenAI(_ urlError:)` — korrekte Fehlerzuordnung
- `localizedMessage` — alle Fälle prüfen

**AppSettings**
- Korrekte Default-Werte beim ersten Start
- Persistenz: setzen → neu initialisieren → lesen

**KeychainService**
- save → load → delete
- Leerer Key → nil zurück

**DictionaryService**
- Hinzufügen, Abrufen, Normalisierung (NFC/NFD)
- Export/Import-Roundtrip

### Stufe 2 – Nach PROJ-34 (LLMProcessorFactory)

**PostProcessor-Protokoll**
- PassthroughPostProcessor gibt Text unverändert zurück
- Factory wählt korrekten Processor für Provider

**OllamaPostProcessor / OpenAIPostProcessor**
- Mocking der URLSession (kein echter Netzwerkaufruf)
- SSE-Parsing: mehrteilige Chunks, `[DONE]`-Terminator
- 401 → `openAIAuthFailed`, andere non-200 → `openAINotReachable`

### Stufe 3 – Nach PROJ-36 (AppState aufteilen)

- `PermissionService`: Mock des Permission-Status
- `TextInsertionService`: korrekte Pasteboard-Nutzung
- `PostProcessingService`: Provider-Routing

## Setup

```swift
// tests/AppTests/ existiert bereits — targets in project.yml ergänzen
// Kein UITest-Target nötig, reine Unit Tests mit XCTest
```

## Abgeschlossene Stufen

### Stufe 1 (74 Tests) – Modelle, Settings, Services
DictoError, AppSettings (inkl. Migration), KeychainService, DictionaryService,
HistoryService, DictationStyle, WhisperLanguage, WhisperModel,
LLMProvider, StorageKey.

### Stufe 2 (47 neue Tests, gesamt 121)
StatsService (record, averageWords, favoriteStyle, Persistenz),
PassthroughPostProcessor, LLMProcessorFactory (Init-Fehler, Konfiguration),
DictoError-Properties (needsAppSettings, systemSettingsURL aus PROJ-38),
TranscriptionState (Equatable inkl. .error(DictoError)),
CustomStyle (Init, Equality, Codable), ShortcutConfig (Defaults, displayKeys, Codable).

## Ziel-Coverage

Stufe 1 + 2 abgedeckt = ~70% der Business-Logik getestet.  
Das reicht aus, um Regressionen bei den häufigsten Änderungen zu erkennen.

## Risiko

Gering — Tests ändern keine Produktions-Logik.
