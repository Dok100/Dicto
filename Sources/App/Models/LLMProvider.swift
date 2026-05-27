import Foundation

/// Welcher LLM-Anbieter für die Textglättung genutzt wird.
/// `.disabled` bedeutet: keine KI-Verarbeitung, Rohtext wird direkt eingefügt.
public enum LLMProvider: String, CaseIterable {
    case disabled
    case ollama
    case openAI = "openai"

    public var label: String {
        switch self {
        case .disabled: "Deaktiviert"
        case .ollama: "Ollama (lokal)"
        case .openAI: "OpenAI API"
        }
    }

    /// Provider die im Anbieter-Picker auswählbar sind (ohne .disabled)
    public static let activeProviders: [LLMProvider] = [.ollama, .openAI]

    /// Provider die Dicto Pro erfordern.
    public var isProFeature: Bool {
        self == .ollama || self == .openAI
    }
}
