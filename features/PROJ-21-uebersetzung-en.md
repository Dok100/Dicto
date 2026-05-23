# PROJ-21 – Deutsch → Englisch Übersetzung

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Neuen Diktat-Stil „→ EN" hinzufügen, der deutschen Diktat-Text automatisch in natürliches Englisch übersetzt – ohne zusätzliche Konfiguration durch den Nutzer.

## Hintergrund

Bisher gab es vier Stile (Neutral, Formell, Locker, Empathisch), die alle auf Deutsch glätteten. Für Nutzer, die auf Englisch kommunizieren oder internationale E-Mails verfassen, fehlte eine direkte Übersetzungsoption. Die Übersetzung erfolgt wie alle anderen Stile über den konfigurierten Ollama-Server – kein externer Dienst, keine Netzwerkverbindung nach außen.

## Umgesetzte Änderungen

### DictationStyle.swift

- Neues `case translate` mit Label `"→ EN"`
- Englischsprachiger System-Prompt, der Ollama anweist, ausschließlich auf Englisch zu antworten:
  - Vollständige, idiomatische Übersetzung des gesamten Textes
  - Entfernung von deutschen Füllwörtern (äh, ähm, halt, irgendwie, sozusagen)
  - Grammatik- und Satzstrukturkorrektur
  - Beibehaltung von Bedeutung und Ton
  - **Keine deutschen Wörter im Output**
  - Text wird via `<diktat>…</diktat>`-Tags übergeben, Rückgabe ohne Tags

### PopoverRootView.swift

- Warnung unterhalb des Stil-Pickers, wenn `translate` ausgewählt, aber Ollama deaktiviert ist:
  ```
  ⚠ Ollama muss aktiviert sein für die Übersetzung.
  ```
- Zeigt sich nur bei diesem Stil – kein dauerhafter UI-Ballast

## Besonderheiten

| Eigenschaft | Details |
|------------|---------|
| Ollama-Pflicht | `translate` funktioniert nur mit aktiviertem Ollama – PassthroughPostProcessor liefert unbearbeiteten deutschen Text |
| Empfohlenes Modell | qwen2.5:32b (beste Qualität, ~20 GB, passt komfortabel auf M4/48 GB RAM) |
| Prompt-Sprache | Englisch (System-Prompt auf Englisch → Ollama antwortet auf Englisch) |
| Kein eigener Prompt | `translate` ignoriert den editierbaren `ollamaPrompt` aus AppSettings |
| 5. Picker-Item | Kurzlabel `→ EN` bleibt kompakt im 340 px breiten Panel |

## Modell-Empfehlung (qwen2.5:32b)

Auf dem M4 MacBook Pro mit 48 GB RAM ist **qwen2.5:32b** die optimale Wahl:

- Deutlich bessere Übersetzungsqualität als kleinere Modelle (14b, glm4)
- Nutzt ~20 GB Unified Memory → kein Memory-Druck
- Kürzere Wartezeiten als erwartet dank M4-Neural-Engine
- Getestet und vom Nutzer als „exzellent" bestätigt

```bash
ollama pull qwen2.5:32b
```

## Testen

1. Popover öffnen → Stil „→ EN" auswählen
2. Ollama aktiviert → Fn drücken → deutschen Satz diktieren → englischer Text wird eingefügt
3. Ollama deaktiviert → Warnung erscheint im Panel; Text wird unverändert (Deutsch) eingefügt
4. Langer Satz mit Füllwörtern: „äh, ich wollte halt mal fragen…" → sauberes englisches Äquivalent
5. Ton-Test: Förmlicher deutscher Text → förmliches Englisch; lockerer Text → natürliches Englisch
