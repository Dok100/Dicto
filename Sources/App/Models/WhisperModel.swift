public enum WhisperModel: String, CaseIterable {
    case base         = "base"
    case largev3turbo = "openai_whisper-large-v3_turbo_954MB"
    case largev3      = "large-v3"

    public var label: String {
        switch self {
        case .base:         return "Base (~150 MB, schnell)"
        case .largev3turbo: return "Large v3 Turbo (~800 MB, empfohlen)"
        case .largev3:      return "Large v3 (~3 GB, maximal präzise)"
        }
    }
}
