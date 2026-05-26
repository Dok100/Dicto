public enum WhisperLanguage: String, CaseIterable {
    case german = "de"
    case english = "en"
    case auto = ""

    public var label: String {
        switch self {
        case .german: "Deutsch"
        case .english: "Englisch"
        case .auto: "Auto (erkennt automatisch)"
        }
    }

    /// nil → Whisper erkennt Sprache selbst
    public var code: String? {
        self == .auto ? nil : rawValue
    }
}
