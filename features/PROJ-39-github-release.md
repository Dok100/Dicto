# PROJ-39 – GitHub Release v0.1.0

## Ziel

Dicto als öffentlich herunterladbare macOS-App auf GitHub veröffentlichen –
signiert, notarisiert und als DMG verpackt.

## Stufen

### Stufe 1 – Vorbereitung ✅ (kein Developer Account nötig)

- [x] `CHANGELOG.md` angelegt (Keep a Changelog Format)
- [x] `make format` + `make test` grün (121 Tests)
- [x] Versionsnummer `0.1.0` in `project.yml` bestätigt
- [x] Makefile: `make archive` und `make notarize` Targets ergänzt
- [x] `scripts/ExportOptions.plist` für Developer ID Export angelegt

### Stufe 2 – Signierung & Notarisierung (wartet auf Apple Developer Account)

- [ ] Developer ID Application Zertifikat im Apple Developer Portal beantragen
- [ ] Zertifikat in Keychain importieren
- [ ] `make archive TEAM_ID=XXXXXXXXXX` ausführen
- [ ] `make notarize TEAM_ID=… APPLE_ID=… APP_PASSWORD=…` ausführen
- [ ] Notarisierungs-Ticket geprüft (`xcrun stapler validate`)

### Stufe 3 – GitHub Release

- [ ] Git Tag setzen: `git tag v0.1.0 && git push origin v0.1.0`
- [ ] GitHub Release Draft anlegen (github.com/Dok100/Dicto → Releases)
- [ ] Release Notes aus `CHANGELOG.md` einfügen
- [ ] `Dicto-0.1.0.dmg` als Asset hochladen
- [ ] Release veröffentlichen

## Befehle (Kurzreferenz)

```bash
# Stufe 2
make archive TEAM_ID=XXXXXXXXXX
make notarize TEAM_ID=XXXXXXXXXX APPLE_ID=deine@email.com APP_PASSWORD=xxxx-xxxx-xxxx-xxxx

# Stufe 3
git tag v0.1.0
git push origin v0.1.0
# → Dann auf GitHub: Releases → Draft a new release → Tag v0.1.0 wählen
```

## Hinweise

- `APP_PASSWORD` ist ein App-spezifisches Passwort (nicht das Apple-ID-Passwort):
  appleid.apple.com → Anmelden → App-spezifische Passwörter → Neues Passwort
- Notarisierung dauert typischerweise 1–5 Minuten
- Ohne Notarisierung zeigt macOS beim ersten Start: *„Dicto kann nicht geöffnet werden, weil es von einem unbekannten Entwickler stammt"*
