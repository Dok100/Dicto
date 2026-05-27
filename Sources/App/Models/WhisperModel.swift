public enum WhisperModel: String, CaseIterable {
    case base
    case largev3turbo = "openai_whisper-large-v3_turbo_954MB"
    case largev3 = "large-v3"

    public var label: String {
        switch self {
        case .base: "Base (~150 MB, schnell)"
        case .largev3turbo: "Large v3 Turbo (~800 MB, empfohlen)"
        case .largev3: "Large v3 (~3 GB, maximal präzise)"
        }
    }

    /// Modelle die Dicto Pro erfordern.
    public var isProFeature: Bool {
        self == .largev3turbo || self == .largev3
    }
}
