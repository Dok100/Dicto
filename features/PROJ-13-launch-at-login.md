# PROJ-13 – Launch at Login

**Status**: Abgeschlossen
**Branch**: main

## Ziel

Dicto startet automatisch beim macOS-Login, ohne manuelle Konfiguration in den Systemeinstellungen.

## Umgesetzte Änderungen

### SettingsView.swift
- `import ServiceManagement` hinzugefügt
- Toggle "Beim Login automatisch starten" ganz oben in den Einstellungen
- Custom `Binding<Bool>` liest `SMAppService.mainApp.status == .enabled` und ruft `register()` / `unregister()` auf
- Orangefarbener Hinweis wenn Status `.requiresApproval` ist

## Technische Details

`SMAppService.mainApp` ist die moderne API (macOS 13+) für Login-Items. macOS verwaltet den Zustand selbst – kein UserDefaults nötig.

Mögliche Status-Werte:
| Status | Bedeutung |
|--------|-----------|
| `.notRegistered` | Nicht aktiviert |
| `.enabled` | Aktiv, startet beim Login |
| `.requiresApproval` | Registriert, wartet auf Nutzer-Genehmigung |
| `.notFound` | App nicht in /Applications |

## Einschränkung

Funktioniert nur wenn die App in `/Applications` oder `~/Applications` liegt. Beim Ausführen direkt aus Xcode/DerivedData schlägt `register()` lautlos fehl.
