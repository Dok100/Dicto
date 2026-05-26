import AppKit

/// Beschreibt eine konfigurierbare Tastenkombination.
/// Zwei Mechanismen:
///   isFlagsBased = true  → Fn-Taste (flagsChanged-Event, keyCode 63)
///   isFlagsBased = false → Normale Taste (keyDown/keyUp-Event)
public struct ShortcutConfig: Codable, Equatable {
    public var isFlagsBased: Bool
    public var keyCode: UInt16
    /// NSEvent.ModifierFlags.rawValue nach .deviceIndependentFlagsMask maskiert
    public var modifierRaw: UInt

    public var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierRaw)
            .intersection([.command, .option, .control, .shift])
    }

    // MARK: – Standard-Shortcuts

    /// Standard Diktat: Fn allein
    static let defaultDictation = ShortcutConfig(isFlagsBased: true, keyCode: 63, modifierRaw: 0)

    /// Standard Transform: ⌥ + Fn
    static let defaultTransform = ShortcutConfig(
        isFlagsBased: true,
        keyCode: 63,
        modifierRaw: NSEvent.ModifierFlags.option.rawValue)

    // MARK: – Anzeige

    /// Tasten-Namen für Badge-Darstellung, z.B. ["⌥", "Fn"] oder ["⌘", "D"]
    var displayKeys: [String] {
        var keys: [String] = []
        let flags = modifierFlags
        if flags.contains(.control) { keys.append("⌃") }
        if flags.contains(.option) { keys.append("⌥") }
        if flags.contains(.shift) { keys.append("⇧") }
        if flags.contains(.command) { keys.append("⌘") }
        keys.append(isFlagsBased ? "Fn" : Self.keyName(for: keyCode))
        return keys
    }

    // MARK: – KeyCode → Anzeigename

    private static func keyName(for code: UInt16) -> String {
        keyCodeNames[code] ?? "(\(code))"
    }

    private static let keyCodeNames: [UInt16: String] = [
        // Buchstaben
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P",
        37: "L", 38: "J", 40: "K", 41: ";", 43: ",", 44: "/",
        45: "N", 46: "M", 47: ".", 50: "`",
        // Sondertasten
        36: "↩", 48: "⇥", 49: "Leer", 51: "⌫", 53: "⎋", 63: "Fn",
        // Pfeiltasten
        123: "←", 124: "→", 125: "↓", 126: "↑",
        // F-Tasten
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]
}
