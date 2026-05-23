import AppKit

/// Spielt kurze akustische Rückmeldungen beim Start und Stop der Aufnahme.
/// Verwendet macOS-Systemsounds – kein eigenes Audio-Asset nötig.
enum SoundFeedback {

    /// Kurzes „Tink" → Aufnahme startet (klar, präzise).
    static func playStart() {
        NSSound(named: "Tink")?.play()
    }

    /// Weiches „Pop" → Aufnahme endet (sanft, abschließend).
    static func playStop() {
        NSSound(named: "Pop")?.play()
    }
}
