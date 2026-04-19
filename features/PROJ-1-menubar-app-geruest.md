# PROJ-1 – Menübar-App-Gerüst

## Ziel

Lauffähiges Xcode-Projekt mit funktionierendem Menübar-Icon und Popover. Kein Swift-Code jenseits des Gerüsts – nur das Fundament, auf dem alle weiteren Phasen aufbauen.

## Scope

- XcodeGen-Projekt (`project.yml`) mit korrekten Einstellungen (macOS 14+, LSUIElement, Mikrofon-Entitlement, Sandbox deaktiviert)
- Makefile mit Targets: `install`, `generate`, `format`, `build`, `test`, `clean`
- `AppDelegate` als `NSApplicationDelegate`, setzt `NSStatusItem` auf
- `MenuBarController` verwaltet `NSStatusItem` und `NSPopover`
- `PopoverRootView` als SwiftUI-Platzhalter mit "Beenden"-Button
- Dokumentationsgerüst: `docs/`, `features/`, `CLAUDE.md`, `README.md`
- Git-Initialisierung mit `.gitignore`

## Out-of-Scope

- Hotkey-Logik (kommt in PROJ-2)
- Audio-Aufnahme (kommt in PROJ-2)
- Transkription (kommt in PROJ-3)
- Text-Einfügung (kommt in PROJ-4)
- Einstellungen (kommen in PROJ-7)

## Akzeptanzkriterien

- [ ] `make generate && make build` läuft durch ohne Fehler
- [ ] App startet: Menübar-Icon erscheint (SF Symbol oder Platzhalter-Icon)
- [ ] Klick auf Icon öffnet Popover mit Platzhalter-Text und "Beenden"-Button
- [ ] "Beenden"-Button beendet die App sauber
- [ ] Kein Dock-Icon sichtbar (LSUIElement=YES wirkt)
- [ ] `.xcodeproj` ist nicht im Git-Repository (per .gitignore ausgeschlossen)
- [ ] Initialer Git-Commit vorhanden

## Umsetzungsnotizen

### Dateistruktur Phase B

```
Sources/App/
  FlowDictateApp.swift      # @main App-Entry, NSApplicationDelegateAdaptor
  AppDelegate.swift          # NSApplicationDelegate, hält MenuBarController
  Services/
    MenuBarController.swift  # NSStatusItem + NSPopover-Verwaltung
  Views/
    PopoverRootView.swift    # SwiftUI Platzhalter-UI
  Info.plist                 # Wird von XcodeGen referenziert
  Dicto.entitlements         # Mikrofon-Entitlement
```

### Wichtige macOS-API-Eigenheiten

**NSStatusItem**: Muss auf dem Main Thread erstellt und gehalten werden. Am besten als `let` in `AppDelegate` oder `MenuBarController`.

**NSPopover + SwiftUI**: `NSPopover.contentViewController` bekommt einen `NSHostingController<PopoverRootView>`. Größe wird über `.frame(width:height:)` auf der SwiftUI-View gesteuert, nicht am Popover selbst.

**LSUIElement**: Mit `LSUIElement=true` gibt es keine `applicationDidFinishLaunching`-basierte Aktivierung. `AppDelegate.applicationDidFinishLaunching` funktioniert aber weiterhin normal.

**App-Lebenszyklus mit `@NSApplicationDelegateAdaptor`**: SwiftUI's `@main`-Struct und `NSApplicationDelegateAdaptor` zusammen: Der AppDelegate übernimmt die Kontrolle über den Menübar-Bereich, SwiftUI bleibt verantwortlich für die Popover-Views.

## Status

In Arbeit – Phase A (Dokumentation + Gerüst) abgeschlossen, wartet auf Review-Freigabe für Phase B (Swift-Code).
