# Runbook

## App starten

```bash
make build
open build/Release/Dicto.app
# oder direkt aus Xcode: Cmd+R
```

## Erststart – Berechtigungen freischalten

Beim ersten Start fordert macOS zwei Berechtigungen:

1. **Mikrofon**: Dialog erscheint automatisch beim ersten Aufnahmeversuch. → Erlauben klicken.
2. **Bedienungshilfen + Eingabe-Überwachung**: macOS öffnet *nicht* automatisch einen Dialog.
   - Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen → Dicto hinzufügen/aktivieren
   - Systemeinstellungen → Datenschutz & Sicherheit → Eingabe-Überwachung → Dicto hinzufügen/aktivieren
   - App danach neu starten

## WhisperKit-Modell herunterladen

Beim ersten Start mit aktiver Transkription lädt WhisperKit das Modell `openai_whisper-large-v3-turbo` (~600 MB) herunter. Fortschritt wird im Popover angezeigt. Einmalig, danach gecacht unter `~/Library/Caches/Dicto/Models/`.

## Ollama-Verbindung prüfen

```bash
curl http://localhost:11434/api/tags
# Sollte JSON mit verfügbaren Modellen zurückgeben
ollama list   # glm-4.7-flash sollte in der Liste sein
```

Falls Ollama nicht läuft: Glättung wird automatisch auf Passthrough zurückgesetzt.

## Logs einsehen

```bash
# Console.app → Nach "Dicto" filtern
# oder:
log show --predicate 'process == "Dicto"' --last 1h
```

## Aufnahme-Cache leeren

```bash
rm -rf ~/Library/Caches/Dicto/
```

## App-Reset (alle Einstellungen zurücksetzen)

```bash
defaults delete de.oliverkern.dicto
```

## Build-Probleme

### XcodeGen-Fehler
```bash
make clean && make generate
```

### SwiftFormat-Fehler
```bash
swiftformat --lint Sources/   # Zeigt Probleme an ohne Änderungen
```

### Accessibility-Permission schlägt fehl
CGEventTap schlägt still fehl, wenn die Berechtigung fehlt. Symptom: Fn-Taste wird nicht erkannt.
→ Systemeinstellungen → Bedienungshilfen prüfen, App entfernen und neu hinzufügen.
