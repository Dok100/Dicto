enum WhisperLanguage: String, CaseIterable {
    case german  = "de"
    case english = "en"
    case auto    = ""

    var label: String {
        switch self {
        case .german:  return "Deutsch"
        case .english: return "Englisch"
        case .auto:    return "Auto (erkennt automatisch)"
        }
    }

    // nil → Whisper erkennt Sprache selbst
    var code: String? {
        self == .auto ? nil : rawValue
    }
}
