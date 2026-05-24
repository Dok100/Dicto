public enum TranscriptionEngine: String, CaseIterable {
    case apple  = "apple"
    case whisper = "whisper"

    public var label: String {
        switch self {
        case .apple:  return "Apple (live, kein Download)"
        case .whisper: return "Whisper (präziser, offline)"
        }
    }
}
