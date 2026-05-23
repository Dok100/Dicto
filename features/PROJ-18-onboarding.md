# PROJ-18 – Onboarding / First-Run-Experience

**Status**: ✅ Abgeschlossen
**Branch**: main

## Ziel

Beim ersten App-Start ein geführtes Onboarding-Fenster zeigen, das:
- erklärt was Dicto macht
- Mikrofon-Permission einholt
- Bedienungshilfen-Permission erklärt und wartet bis erteilt
- die wichtigsten Shortcuts zeigt

## Umgesetzte Änderungen

### OnboardingView.swift (neu)
- 3-Schritt-Flow: Mikrofon → Bedienungshilfen → Fertig
- Step-Indicator mit Kreisen + Verbindungslinien (animiert)
- **Schritt 1 – Mikrofon**: `AVCaptureDevice.requestAccess` → Systemdialog; zeigt Checkmark wenn erteilt
- **Schritt 2 – Bedienungshilfen**: `AXIsProcessTrustedWithOptions` öffnet Systemeinstellungen;
  Timer pollt alle 0,5 s bis `AXIsProcessTrusted()` true ist → Button wird automatisch aktiv
- **Schritt 3 – Fertig**: `party.popper.fill`-Icon, Shortcut-Übersicht (identisches Badge-Design wie Panel)
- Bereits erteilte Permissions werden erkannt → entsprechende Schritte zeigen sofort Checkmark
- `.regularMaterial`-Hintergrund (Frosted Glass, konsistent mit Panel)

### OnboardingWindowController.swift (neu)
- `UserDefaults`-Flag `onboardingCompleted` als Single Source of Truth
- `isNeeded: Bool` – statische Property für Prüfung beim Start
- `markCompleted()` – wird vom `onComplete`-Callback aufgerufen
- Fenster: `.titled + .closable + .fullSizeContentView`, transparent, zentriert, nicht resizable

### MenuBarController.swift
- `onboardingWindowController` Property hinzugefügt
- Bei `init`: prüft `OnboardingWindowController.isNeeded`
- Zeigt Onboarding mit 0,3 s Verzögerung (Menübar muss erst aufgebaut sein)
- Nach Abschluss: Controller wird freigegeben, App läuft normal weiter

## Technische Details

- **Einmaligkeit**: `UserDefaults.standard.bool(forKey: "onboardingCompleted")`
  – gesetzt beim Klick auf "Loslegen" in Schritt 3
- **AX-Polling**: `Timer.scheduledTimer(withTimeInterval: 0.5)` – wird in `onDisappear` invalidiert
- **Permission-Skip**: `AVCaptureDevice.authorizationStatus` / `AXIsProcessTrusted()` werden in
  `onAppear` geprüft; bereits erteilte Permissions überspringen den Warte-Zustand
- **Testen**: `defaults delete com.oliverkern.Dicto onboardingCompleted` setzt das Flag zurück
