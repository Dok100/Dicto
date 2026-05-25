# PROJ-33 – Storage-Konstanten

**Status:** Offen  
**Aufwand:** S (< 1 Stunde)  
**Typ:** Refactoring

## Problem

UserDefaults-Keys und Keychain-Keys sind als hartcodierte Strings über mehrere Dateien verteilt:

```swift
UserDefaults.standard.bool(forKey: "onboardingCompleted")
UserDefaults.standard.set(true, forKey: "llmProvider")
KeychainService.shared.load(forKey: "openAIApiKey")
```

Tippfehler werden erst zur Laufzeit sichtbar. Umbenennen ist fehleranfällig.

## Ziel

Alle Schlüssel in einem zentralen `enum StorageKey` bündeln:

```swift
enum StorageKey {
    enum UserDefaults {
        static let onboardingCompleted = "onboardingCompleted"
        static let llmProvider         = "llmProvider"
        static let openAIModel         = "openAIModel"
        static let openAIBaseURL       = "openAIBaseURL"
        // …alle weiteren Keys
    }
    enum Keychain {
        static let openAIApiKey = "openAIApiKey"
    }
}
```

## Betroffene Dateien

- `Sources/App/Models/AppSettings.swift` (alle UserDefaults-Keys)
- `Sources/App/Services/OnboardingWindowController.swift` (onboardingCompleted)
- `Sources/App/Services/KeychainService.swift` (Keychain-Keys)

## Risiko

Sehr gering — rein mechanisches Umbenennen, kein Logik-Eingriff.
