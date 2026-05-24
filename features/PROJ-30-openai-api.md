# PROJ-30 – OpenAI API als LLM-Alternative

## Ziel

Nutzer mit wenig RAM oder ohne lokales Ollama können OpenAIs Chat-Completions-API
als Alternative für die Textglättung verwenden. Gleicher Workflow, gleiche Streaming-
Qualität – aber Cloud-basiert statt lokal.

## Verhalten

- Neuer Picker „Anbieter" in den KI-Einstellungen: **Ollama (lokal)** / **OpenAI API**
- Beide Provider nutzen denselben System-Prompt und die gleiche Streaming-Logik
- API-Key wird **im macOS Keychain** gespeichert – nie in UserDefaults oder auf Disk
- Auge-Symbol erlaubt temporäres Einblenden des Keys beim Eingeben
- Basis-URL konfigurierbar → kompatibel mit OpenAI-Proxies, Groq, LM Studio u.a.
- Standard-Modell: `gpt-4o-mini` (schnell, günstig, sehr gute Qualität)
- Fehler werden klar auf Deutsch gemeldet (kein Key, nicht erreichbar, Timeout)

## Sicherheit

| Aspekt | Umsetzung |
|--------|-----------|
| Speicherung | macOS Keychain (`kSecClassGenericPassword`, `de.oliverkern.dicto`) |
| Transport | HTTPS (URL-Validierung erzwungen) |
| Sichtbarkeit | SecureField by default, Auge-Toggle für Eingabe |
| Scope | Nur diese App hat Keychain-Zugriff (Service-ID eindeutig) |

## Implementierung

**`KeychainService`** (`Sources/App/Services/KeychainService.swift`)
- `save(_:forKey:)` – erstellt oder überschreibt per `SecItemUpdate`/`SecItemAdd`
- `load(forKey:)` – liest via `SecItemCopyMatching`
- `delete(forKey:)` – löscht via `SecItemDelete`
- Service-ID: `de.oliverkern.dicto`

**`LLMProvider`** (`Sources/App/Models/LLMProvider.swift`)
- Enum `.ollama` / `.openAI`
- Gespeichert in UserDefaults als rawValue-String

**`OpenAIPostProcessor`** (`Sources/App/PostProcessors/OpenAIPostProcessor.swift`)
- SSE-Streaming: Zeilen mit `data: ` Präfix, `[DONE]` als Abschluss
- Decodiert `choices[0].delta.content`
- `Authorization: Bearer {apiKey}` Header
- Throwing Init: wirft `openAIKeyMissing` wenn Key leer

**`OpenAITransformProcessor`** (`Sources/App/PostProcessors/OpenAITransformProcessor.swift`)
- Identisch zu `OpenAIPostProcessor` aber mit Transform-System-Prompt

**`AppSettings`**
- `llmProvider: LLMProvider` (UserDefaults)
- `openAIModel: String` (UserDefaults, Default: `gpt-4o-mini`)
- `openAIBaseURL: String` (UserDefaults, Default: `https://api.openai.com/v1`)
- `openAIApiKey: String` (Keychain, nicht @Published)

**`AppState`**
- `handleTranscriptionDone` und `handleTransformDone` wählen per `switch settings.llmProvider`
  zwischen Ollama- und OpenAI-Processor

**`project.yml`** – `Security.framework` als dependency hinzugefügt

## Kompatible APIs (via Basis-URL)

- OpenAI: `https://api.openai.com/v1`
- Groq: `https://api.groq.com/openai/v1`
- LM Studio: `http://localhost:1234/v1`
- Together AI, Mistral API, etc.
