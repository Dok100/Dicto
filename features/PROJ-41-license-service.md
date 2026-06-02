# PROJ-41 – LicenseService + Dicto Pro Feature-Gates ✅

## Ziel

Dicto erhält eine Monetarisierungsebene: Bestimmte Features erfordern
eine kostenpflichtige Lizenz (Dicto Pro, €19 Einmalkauf). Der Lizenzstatus
wird offline-fähig gecacht und beim App-Start im Hintergrund validiert.

## Hintergrund

Dicto ist privacy-first und lokal – das schließt ein Abo-Modell aus.
Ein einmaliger Kauf via LemonSqueezy (Merchant of Record, übernimmt EU-MwSt.)
passt zur Zielgruppe und zum Wertversprechen der App.

## Architektur

### LicenseService

`@MainActor`-Singleton mit drei Zuständen:
- `isPro: Bool` – aus UserDefaults gecacht, sofort beim App-Start verfügbar
- `isValidating: Bool` – Lade-Indikator für die UI
- `activationError: String?` – Fehlermeldung bei fehlgeschlagener Aktivierung

### Aktivierungsflow

```
Nutzer gibt Key ein
    → POST /v1/licenses/activate (LemonSqueezy API)
    → Variant-ID prüfen (1708450 = Dicto Pro)
    → License Key + Instance-ID in Keychain speichern
    → isPro = true + UserDefaults-Cache setzen
```

### Offline-Strategie

```
App-Start:
    isPro = UserDefaults.licenseActivated   ← sofort, kein Netzwerk
    Task { await validateOnLaunch() }       ← Hintergrund-Check
        ├── Erfolg → Cache aktualisieren
        └── Netzwerkfehler → Cache-Status behalten
```

### Deaktivierung

`DELETE /v1/licenses/deactivate` (best effort) → Keychain löschen →
`isPro = false` → Slot auf LemonSqueezy wieder frei (max. 3 Geräte)

## Umgesetzte Dateien

| Datei | Änderung |
|-------|----------|
| `Services/LicenseService.swift` | Neu – Aktivierung, Validierung, Deaktivierung |
| `Views/LicenseSettingsView.swift` | Neu – Lizenz-Tab in den Einstellungen |
| `Services/SettingsWindowController.swift` | Neuer Tab „Lizenz" (Siegel-Icon) |
| `AppDelegate.swift` | `validateOnLaunch()` beim App-Start |
| `Models/StorageKey.swift` | `licenseKey`, `instanceId` (Keychain), `licenseActivated` (Defaults) |
| `Models/WhisperModel.swift` | `isProFeature` – Large v3 Turbo + Large v3 |
| `Models/LLMProvider.swift` | `isProFeature` – Ollama + OpenAI |
| `Services/HistoryService.swift` | `maxEntries`: 10 (Free) / 20 (Pro) |
| `Views/GeneralSettingsView.swift` | Lock-Icon bei Pro-Whisper-Modellen |
| `Views/AISettingsView.swift` | Lock-Icon bei Pro-LLM-Anbietern |

## Feature-Split: Free vs. Pro

| Feature | Free | Pro |
|---------|------|-----|
| Apple Speech Engine | ✅ | ✅ |
| WhisperKit Base | ✅ | ✅ |
| WhisperKit Large v3 Turbo | 🔒 | ✅ |
| WhisperKit Large v3 | 🔒 | ✅ |
| Ollama Integration | 🔒 | ✅ |
| OpenAI API | 🔒 | ✅ |
| Eigene Stile | 🔒 | ✅ |
| Diktat-Verlauf | 10 Einträge | 20 Einträge |

## LemonSqueezy-Konfiguration

- **Produkt:** Dicto Pro
- **Preis:** €19 (Einmalkauf, steuerinklusiv)
- **Variant-ID:** 1733412
- **Aktivierungslimit:** 3 Geräte pro Key
- **Lizenzdauer:** Unbegrenzt
- **Store:** dicto.lemonsqueezy.com (Aktivierung ausstehend)

## Verwandte Dokumente

- `docs/privacy-policy.md` – Datenschutzerklärung (LemonSqueezy-Abschnitt)
- `docs/refund-policy.md` – 14-Tage-Rückgaberecht
