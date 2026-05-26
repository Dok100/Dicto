public enum TranscriptionEngine: String, CaseIterable {
    case apple
    case whisper

    public var label: String {
        switch self {
        case .apple: "Apple (live, kein Download)"
        case .whisper: "Whisper (präziser, offline)"
        }
    }
}
