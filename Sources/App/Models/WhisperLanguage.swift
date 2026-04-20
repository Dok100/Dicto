public enum WhisperLanguage: String, CaseIterable {
    case german  = "de"
    case english = "en"
    case auto    = ""

    public var label: String {
        switch self {
        case .german:  return "Deutsch"
        case .english: return "Englisch"
        case .auto:    return "Auto (erkennt automatisch)"
        }
    }

    // nil → Whisper erkennt Sprache selbst
    public var code: String? {
        self == .auto ? nil : rawValue
    }
}
