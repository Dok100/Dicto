import AppKit

/// Spielt kurze akustische Rückmeldungen beim Start und Stop der Aufnahme.
/// Lädt Systemsounds direkt via Dateipfad – zuverlässiger als NSSound(named:).
enum SoundFeedback {
    /// Kurzes „Tink" → Aufnahme startet (klar, präzise).
    static func playStart() {
        play(named: "Tink")
    }

    /// Weiches „Pop" → Aufnahme endet (sanft, abschließend).
    static func playStop() {
        play(named: "Pop")
    }

    // MARK: – Intern

    private static func play(named name: String) {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        guard let sound = NSSound(contentsOf: url, byReference: false) else { return }
        sound.play()
    }
}
