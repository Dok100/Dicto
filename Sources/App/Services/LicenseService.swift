import Foundation

/// Verwaltet den Dicto-Pro-Lizenzstatus.
///
/// Ablauf:
/// 1. App-Start: `isPro` wird sofort aus UserDefaults geladen (offline-fähig).
/// 2. Im Hintergrund: LemonSqueezy-API validiert den gespeicherten Key.
/// 3. Nutzer gibt Key ein → `activate(key:)` → bei Erfolg in Keychain + UserDefaults cachen.
///
/// Alle UI-Updates laufen auf dem Main-Actor, da LicenseService @Published-Properties hat.
@MainActor
final class LicenseService: ObservableObject {

    static let shared = LicenseService()

    // ─── LemonSqueezy-Konfiguration ────────────────────────────────────────
    // Variant-ID aus dem LemonSqueezy-Dashboard (Produkt → Variante → ID in der URL).
    // Verhindert, dass Keys fremder Produkte akzeptiert werden.
    // Live-Variante: 1733412 / Test-Variante: 1708450
    private static let acceptedVariantIds: Set<Int> = [1733412, 1708450]

    private static let activateURL   = URL(string: "https://api.lemonsqueezy.com/v1/licenses/activate")!
    private static let validateURL   = URL(string: "https://api.lemonsqueezy.com/v1/licenses/validate")!
    private static let deactivateURL = URL(string: "https://api.lemonsqueezy.com/v1/licenses/deactivate")!

    // ─── Öffentlicher Zustand ──────────────────────────────────────────────
    @Published private(set) var isPro: Bool = false
    @Published private(set) var isValidating: Bool = false
    @Published private(set) var activationError: String? = nil

    // ─── Keychain-Zugriff ──────────────────────────────────────────────────
    private var storedKey: String? {
        get { KeychainService.shared.load(forKey: StorageKey.Keychain.licenseKey) }
        set {
            if let v = newValue {
                KeychainService.shared.save(v, forKey: StorageKey.Keychain.licenseKey)
            } else {
                KeychainService.shared.delete(forKey: StorageKey.Keychain.licenseKey)
            }
        }
    }

    private var storedInstanceId: String? {
        get { KeychainService.shared.load(forKey: StorageKey.Keychain.instanceId) }
        set {
            if let v = newValue {
                KeychainService.shared.save(v, forKey: StorageKey.Keychain.instanceId)
            } else {
                KeychainService.shared.delete(forKey: StorageKey.Keychain.instanceId)
            }
        }
    }

    private init() {
        // Gecachten Status sofort laden – kein Netzwerk nötig
        isPro = UserDefaults.standard.bool(forKey: StorageKey.Defaults.licenseActivated)
    }

    // MARK: – App-Start-Validierung

    /// Wird einmalig beim App-Start aufgerufen. Prüft im Hintergrund ob der
    /// gecachte Key noch gültig ist. Bei Netzwerkfehler bleibt der Cache-Status erhalten.
    func validateOnLaunch() async {
        guard let key = storedKey, let instanceId = storedInstanceId else { return }
        do {
            let valid = try await validate(key: key, instanceId: instanceId)
            isPro = valid
            UserDefaults.standard.set(valid, forKey: StorageKey.Defaults.licenseActivated)
        } catch {
            // Netzwerkfehler → offline-Cache behalten, kein isPro-Reset
        }
    }

    // MARK: – Aktivierung

    /// Aktiviert einen neuen License Key gegen die LemonSqueezy-API.
    /// Bei Erfolg werden Key und Instance-ID in den Keychain gespeichert.
    func activate(key: String) async {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            activationError = "Bitte einen Lizenzschlüssel eingeben."
            return
        }

        isValidating = true
        activationError = nil
        defer { isValidating = false }

        do {
            var request = urlEncodedRequest(url: Self.activateURL)
            let deviceName = (Host.current().localizedName ?? "Mac")
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Mac"
            request.httpBody = "license_key=\(trimmed)&instance_name=\(deviceName)".data(using: .utf8)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                activationError = "Ungültige Server-Antwort."
                return
            }

            let result = try JSONDecoder().decode(LicenseActivateResponse.self, from: data)

            if http.statusCode == 200 && result.activated {
                // Variant-ID prüfen (nur wenn expectedVariantId gesetzt ist)
                if let variantId = result.meta?.variantId,
                   !Self.acceptedVariantIds.contains(variantId)
                {
                    activationError = "Dieser Schlüssel gehört nicht zu Dicto Pro."
                    return
                }

                storedKey = trimmed
                storedInstanceId = result.instance?.id
                isPro = true
                UserDefaults.standard.set(true, forKey: StorageKey.Defaults.licenseActivated)

            } else {
                activationError = result.error ?? "Aktivierung fehlgeschlagen. Prüfe den Schlüssel."
            }

        } catch {
            activationError = "Netzwerkfehler: \(error.localizedDescription)"
        }
    }

    // MARK: – Deaktivierung

    /// Deaktiviert die Lizenz auf diesem Gerät und löscht alle lokalen Daten.
    /// Der API-Call ist „best effort" – lokale Daten werden immer gelöscht.
    func deactivate() async {
        if let key = storedKey, let instanceId = storedInstanceId {
            var request = urlEncodedRequest(url: Self.deactivateURL, method: "DELETE")
            request.httpBody = "license_key=\(key)&instance_id=\(instanceId)".data(using: .utf8)
            _ = try? await URLSession.shared.data(for: request)
        }

        storedKey = nil
        storedInstanceId = nil
        isPro = false
        UserDefaults.standard.set(false, forKey: StorageKey.Defaults.licenseActivated)
    }

    // MARK: – Interne Validierung

    private func validate(key: String, instanceId: String) async throws -> Bool {
        var request = urlEncodedRequest(url: Self.validateURL)
        request.httpBody = "license_key=\(key)&instance_id=\(instanceId)".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(LicenseValidateResponse.self, from: data)
        return result.valid
    }

    // MARK: – Hilfsfunktion

    private func urlEncodedRequest(url: URL, method: String = "POST") -> URLRequest {
        var r = URLRequest(url: url)
        r.httpMethod = method
        r.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        r.setValue("application/json", forHTTPHeaderField: "Accept")
        return r
    }
}

// MARK: – API-Response-Modelle (privat)

private struct LicenseActivateResponse: Decodable {
    let activated: Bool
    let error: String?
    let instance: InstanceInfo?
    let meta: MetaInfo?

    struct InstanceInfo: Decodable {
        let id: String
        let name: String
    }

    struct MetaInfo: Decodable {
        let variantId: Int

        enum CodingKeys: String, CodingKey {
            case variantId = "variant_id"
        }
    }
}

private struct LicenseValidateResponse: Decodable {
    let valid: Bool
    let error: String?
}
