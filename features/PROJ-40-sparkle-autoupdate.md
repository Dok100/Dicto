# PROJ-40 – Sparkle Auto-Update

## Ziel

Nutzer werden automatisch über neue Dicto-Versionen informiert und können
Updates mit einem Klick installieren – ohne GitHub manuell zu besuchen.

## Hintergrund

Sparkle ist der De-facto-Standard für macOS-Auto-Updates außerhalb des App Store.
Es wird von Sublime Text, Tower, Figma, BBEdit und hunderten anderen Apps genutzt.

## Wie es funktioniert

1. Dicto prüft beim Start (und alle 24 h) eine öffentliche `appcast.xml`-Datei
2. Ist eine neuere Version verfügbar, erscheint ein nativer macOS-Dialog
3. Nutzer klicken „Aktualisieren" → Download, Installation, Neustart – automatisch
4. `appcast.xml` wird bei jedem GitHub Release manuell (oder per Skript) aktualisiert

## Geplante Umsetzung

### Integration

- Sparkle via Swift Package Manager einbinden (github.com/sparkle-project/Sparkle)
- `SUFeedURL` in `Info.plist` eintragen (GitHub Pages oder raw GitHub URL)
- `SPUStandardUpdaterController` in `AppDelegate` initialisieren
- „Nach Updates suchen" Menüpunkt im Menübar-Menü ergänzen

### Hosting der appcast.xml

Die einfachste Option: die Datei direkt im GitHub-Repo unter `docs/appcast.xml`
hosten – GitHub Pages liefert sie dann als öffentliche URL.

### appcast.xml Beispiel

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Dicto</title>
    <item>
      <title>Version 0.2.0</title>
      <sparkle:version>2</sparkle:version>
      <sparkle:shortVersionString>0.2.0</sparkle:shortVersionString>
      <pubDate>Mon, 01 Jun 2026 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/Dok100/Dicto/releases/download/v0.2.0/Dicto-0.2.0.dmg"
        sparkle:edDSASignature="..."
        length="12345678"
        type="application/octet-stream"/>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
    </item>
  </channel>
</rss>
```

## Voraussetzungen

- PROJ-39 abgeschlossen (Developer ID, Notarisierung läuft)
- GitHub Pages für das Repository aktiviert
- EdDSA-Schlüsselpaar für Sparkle generiert (einmalig, `generate_keys` Tool von Sparkle)

## Abhängigkeit

Wird nach PROJ-39 Stufe 2 umgesetzt.
