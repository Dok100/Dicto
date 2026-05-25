# PROJ-35 – Provider-Konsolidierung (ollamaEnabled entfernen)

**Status:** Offen  
**Aufwand:** S–M (1–2 Stunden)  
**Typ:** Refactoring

## Problem

Es gibt zwei konkurrierende Wahrheiten für denselben Sachverhalt:

```swift
var ollamaEnabled: Bool       // "Ist KI-Glättung aktiv?"
var llmProvider: LLMProvider  // "Welcher Provider?"
```

Wenn `llmProvider == .openAI`, ist Ollama implizit deaktiviert — aber `ollamaEnabled`
muss trotzdem separat auf `false` gesetzt werden. Im UI gibt es Warnungen wie
`"Ollama muss aktiviert sein"`, die auch beim OpenAI-Provider erscheinen können.

## Ziel

`ollamaEnabled` wird zu einer computed property (oder entfernt):

```swift
// Option A: computed property (abwärtskompatibel mit UserDefaults)
var llmEnabled: Bool {
    get { llmProvider != .none }  // oder separates Flag für "KI aus"
    set { ... }
}

// Option B: llmProvider bekommt einen .disabled-Case
enum LLMProvider: String, CaseIterable {
    case disabled = "disabled"
    case ollama   = "ollama"
    case openAI   = "openai"
}
```

Option B ist sauberer: Ein einziges Enum beschreibt alle Zustände vollständig.

## Migration

`ollamaEnabled == false` → `llmProvider = .disabled`  
`ollamaEnabled == true && provider == .ollama` → `llmProvider = .ollama`

UserDefaults-Migration beim App-Start: alten Key lesen, neuen setzen, alten löschen.

## Betroffene Dateien

- `Sources/App/Models/AppSettings.swift`
- `Sources/App/Models/LLMProvider.swift`
- `Sources/App/Models/AppState.swift`
- `Sources/App/Views/AISettingsView.swift`
- `Sources/App/Views/PopoverRootView.swift` (ollamaWarning-Checks)

## Risiko

Mittel — UserDefaults-Migration muss korrekt sein, sonst verlieren Nutzer ihre
Einstellung beim Update. Migrations-Code schreiben und testen.
