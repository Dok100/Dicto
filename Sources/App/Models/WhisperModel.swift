public enum WhisperModel: String, CaseIterable {
    case base
    case largev3 = "large-v3"

    public var label: String {
        switch self {
        case .base: "Base (~150 MB, schnell)"
        case .largev3: "Large v3 (~3 GB, maximal präzise)"
        }
    }

    /// Modelle die Dicto Pro erfordern.
    public var isProFeature: Bool {
        self == .largev3
    }
}
