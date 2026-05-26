# PROJ-40 – Sparkle Auto-Update ✅

## Ziel

Nutzer werden automatisch über neue Dicto-Versionen informiert und können
Updates mit einem Klick installieren – ohne GitHub manuell zu besuchen.

## Hintergrund

Sparkle ist der De-facto-Standard für macOS-Auto-Updates außerhalb des App Store.
Es wird von Sublime Text, Tower, Figma, BBEdit und hunderten anderen Apps genutzt.

## Wie es funktioniert

1. Dicto prüft beim Start (und alle 24 h) die öffentliche `appcast.xml`-Datei
2. Ist eine neuere Version verfügbar, erscheint ein nativer macOS-Dialog
3. Nutzer klicken „Aktualisieren" → Download, Installation, Neustart – automatisch
4. `appcast.xml` wird bei jedem GitHub Release aktualisiert (s. Checkliste unten)

## Umgesetzt

### Integration

- [x] Sparkle 2.9.2 via Swift Package Manager (`project.yml`)
- [x] `SUFeedURL` in `Info.plist` eingetragen (`https://dok100.github.io/Dicto/appcast.xml`)
- [x] `SUPublicEDKey` in `Info.plist` eingetragen (EdDSA-Schlüssel)
- [x] `SPUStandardUpdaterController` in `AppDelegate` initialisiert (`startingUpdater: true`)
- [x] Rechtsklick-Kontextmenü am Menübar-Icon: „Nach Updates suchen…" + „Dicto beenden"
- [x] Privater EdDSA-Schlüssel sicher im macOS Keychain gespeichert (einmalig, `generate_keys`)

### Hosting der appcast.xml

- [x] `docs/appcast.xml` im Repo angelegt (v0.1.0 mit EdDSA-Signatur)
- [ ] GitHub Pages aktiviert (Branch: `main`, Ordner: `/docs`) → Einstellungen → Pages
- URL: `https://dok100.github.io/Dicto/appcast.xml`

## appcast.xml – Checkliste für jeden neuen Release

Bei jedem GitHub Release diese Schritte ausführen:

```bash
# 1. DMG signieren (privater Schlüssel liegt im Keychain)
sign_update release/Dicto-X.Y.Z.dmg

# 2. docs/appcast.xml: neues <item> oben einfügen (altes drin lassen!)
#    - <sparkle:version> = CFBundleVersion (Integer, bei jedem Release +1)
#    - <sparkle:shortVersionString> = X.Y.Z
#    - sparkle:edSignature = Ausgabe von sign_update
#    - length = Dateigröße in Bytes

# 3. Commit + Push → GitHub Pages liefert automatisch die neue XML aus
git add docs/appcast.xml
git commit -m "release: appcast.xml für vX.Y.Z aktualisiert"
git push
```

## Voraussetzungen

- [x] PROJ-39 abgeschlossen (Developer ID, Notarisierung läuft)
- [ ] GitHub Pages für das Repository aktiviert
- [x] EdDSA-Schlüsselpaar generiert (im Keychain gespeichert)
