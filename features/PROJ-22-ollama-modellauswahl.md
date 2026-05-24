# PROJ-22 – Ollama Modellauswahl

## Ziel

Statt den Modellnamen manuell einzutippen, zeigt Dicto ein Dropdown mit allen lokal
installierten Ollama-Modellen. Kein Tippfehler mehr, sofortiger Überblick über
verfügbare Modelle.

## Verhalten

- Beim Öffnen der KI-Einstellungen wird `/api/tags` abgefragt (Timeout 4 s)
- **Modelle gefunden** → Picker-Dropdown mit sortierten Modellnamen
- **Ollama nicht erreichbar** → Textfeld als Fallback (wie bisher)
- Wenn das aktuell gespeicherte Modell nicht in der Liste ist, erscheint es als
  `„modellname (manuell)"` im Picker
- Bei Endpoint-Wechsel wird die Liste automatisch neu geladen (`.task(id: ollamaBaseURL)`)
- Ladeindikator (ProgressView) während des Abrufs sichtbar

## Implementierung

**`AISettingsView`**
- `@State private var availableModels: [String]`
- `@State private var loadingModels: Bool`
- `fetchModels()` ruft `{ollamaBaseURL}/api/tags` ab und dekodiert `OllamaTagsResponse`
- Modell-Feld wechselt zwischen `TextField` und `Picker` je nach `availableModels.isEmpty`

**`OllamaTagsResponse`** (privates Decodable am Ende der Datei):
```swift
struct OllamaTagsResponse: Decodable {
    struct Model: Decodable { let name: String }
    let models: [Model]
}
```
