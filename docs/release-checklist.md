# Release-Checkliste

## Vor jedem Release

### Code-Qualität
- [ ] `make format` ausgeführt, keine SwiftFormat-Warnungen
- [ ] `make build` grün
- [ ] `make test` grün (falls Tests vorhanden)
- [ ] Keine Compiler-Warnings

### Funktionale Tests (manuell)
- [ ] App startet ohne Absturz
- [ ] Menübar-Icon erscheint
- [ ] Popover öffnet/schließt per Klick auf Icon
- [ ] Fn-Taste startet Aufnahme (roter Indikator im Popover)
- [ ] Fn-Taste loslassen stoppt Aufnahme und startet Transkription
- [ ] Transkribierter Text wird korrekt an Cursor-Position eingefügt
- [ ] Alter Clipboard-Inhalt wird nach Einfügen wiederhergestellt
- [ ] Beenden-Button funktioniert

### Berechtigungen
- [ ] Mikrofon-Dialog erscheint beim ersten Aufnahmeversuch
- [ ] Ohne Accessibility-Berechtigung: verständliche Fehlermeldung im Popover
- [ ] Ohne Input-Monitoring-Berechtigung: verständliche Fehlermeldung

### Optionale Features (ab PROJ-6)
- [ ] Ollama läuft → Glättung aktivierbar
- [ ] Ollama nicht erreichbar → Fallback auf Passthrough, kein Absturz

### Dokumentation
- [ ] `docs/decision-log.md` aktuell
- [ ] `CLAUDE.md` Phasenstand aktuell
- [ ] `README.md` stimmt mit aktuellem Feature-Stand überein

### Git
- [ ] Alle Änderungen committed
- [ ] Branch gemergt nach main
- [ ] Versionsnummer in `project.yml` (CFBundleShortVersionString) erhöht
- [ ] Git-Tag gesetzt: `git tag v0.x.0`
