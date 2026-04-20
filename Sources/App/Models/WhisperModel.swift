public enum WhisperModel: String, CaseIterable {
    case base = "base"
    case largev3 = "large-v3"

    public var label: String {
        switch self {
        case .base:    return "Base (~150 MB, schnell)"
        case .largev3: return "Large v3 (~3 GB, präzise)"
        }
    }
}
