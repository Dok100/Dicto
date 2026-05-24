# PROJ-29 – Apple Speech Engine

## Ziel

Apples eingebaute `SFSpeechRecognizer`-Engine als Alternative zu WhisperKit anbieten.
Kein Download nötig → niedrige Einstiegshürde. Text erscheint live während der Aufnahme.

## Verhalten

| | Apple Speech | Whisper |
|---|---|---|
| Download | Keiner | 150 MB – 3 GB |
| Transkription | Live während Aufnahme | Nach Aufnahme (batch) |
| Qualität | Gut (Alltagssprache) | Sehr gut (Fachvokabular) |
| Offline | Ja (on-device) | Ja |

**Mit Ollama aktiv:** Apple Speech-Partials werden unterdrückt – Panel bleibt still
während der Aufnahme, danach folgt nur das Ollama-Streaming. Kein doppelter Text.

**Ohne Ollama:** Text erscheint live Wort für Wort während die Taste gehalten wird.

## Einstellungen

Neuer Bereich „Spracherkennung" in Einstellungen → Allgemein:
- `Apple (live, kein Download)` 
- `Whisper (präziser, offline)`

Whisper-Modellauswahl wird nur angezeigt wenn Whisper gewählt ist.

## Implementierung

**`TranscriptionEngine`** – neues Enum (`.apple` / `.whisper`)

**`AppleSpeechService`**
- `AVAudioEngine` mit Mikrofon-Tap → `SFSpeechAudioBufferRecognitionRequest`
- `requiresOnDeviceRecognition = true` → vollständig lokal, kein Apple-Server
- `onPartialResult`, `onFinalResult`, `onError` Callbacks
- `didFireFinalResult`-Flag verhindert doppelten finalen Callback
  (SFSpeechRecognitionTask kann `isFinal = true` mehrfach feuern)

**`AppState`**
- Hotkey-Callbacks prüfen `settings.transcriptionEngine` und routen zu Apple Speech
  oder AudioService+WhisperService
- Apple Speech Partials nur anzeigen wenn kein Ollama folgt
- `isRecording` wird bei Apple Speech erst in `onFinalResult` zurückgesetzt

**`project.yml`** – `NSSpeechRecognitionUsageDescription` ergänzt

**`DictoError`** – `appleSpeechDenied`, `appleSpeechUnavailable`

## Bekannte Einschränkungen

- `requiresOnDeviceRecognition = true` kann bei nicht verfügbaren Modellen silent fehlschlagen
- Interpunktion weniger zuverlässig als Whisper
- Fachvokabular schlechter als Large v3 / Turbo
