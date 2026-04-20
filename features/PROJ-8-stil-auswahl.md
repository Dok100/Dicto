# PROJ-8 – Stil-Auswahl im Popover

**Status**: Abgeschlossen
**Branch**: proj-2-hotkey-audio (auf main)

## Ziel

Nutzer kann direkt im Popover zwischen vier Diktat-Stilen wählen, die den Ollama-System-Prompt beeinflussen.

## Umgesetzte Änderungen

### DictationStyle.swift (neu)
- `enum DictationStyle: String, CaseIterable` mit Fällen `neutral`, `formal`, `casual`, `empathic`
- `label`-Property für UI (Neutral / Formell / Locker / Empathisch)
- `systemPrompt: String?` – `nil` für Neutral (verwendet editierbaren AppSettings-Prompt), vollständige eigenständige Prompts für die anderen drei Stile

### AppState.swift
- `@Published var dictationStyle: DictationStyle` mit UserDefaults-Persistenz
- `handleTranscriptionDone`: `effectivePrompt = dictationStyle.systemPrompt ?? settings.ollamaPrompt`

### PopoverRootView.swift
- Segmented Picker mit allen vier Stilen, deaktiviert während Aufnahme

## Stil-Prompts

| Stil | Prompt-Fokus |
|------|-------------|
| Neutral | Editierbarer Prompt aus Einstellungen (AppSettings.defaultPrompt) |
| Formell | Geschäftskommunikation, Konjunktiv, vollständige Sätze, kein "Aber"/"Und" |
| Locker | Informell, Umgangssprache erlaubt, kein Konjunktiv, kein Englisch |
| Empathisch | Persönlich/sensibel, weiche Übergänge, "Du"-Anrede, menschliche Wärme |

## Hinweis

Locker und Empathisch zeigen mit glm4 Einschränkungen (Füllwörter bleiben, wenig Nuancierung). Verbesserung möglich durch Wechsel zu einem stärkeren Modell (z.B. llama3.1:8b, qwen2.5:7b).
