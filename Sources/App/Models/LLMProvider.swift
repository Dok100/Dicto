import Foundation

/// Welcher LLM-Anbieter für die Textglättung genutzt wird.
/// `.disabled` bedeutet: keine KI-Verarbeitung, Rohtext wird direkt eingefügt.
public enum LLMProvider: String, CaseIterable {
    case disabled = "disabled"
    case ollama   = "ollama"
    case openAI   = "openai"

    public var label: String {
        switch self {
        case .disabled: return "Deaktiviert"
        case .ollama:   return "Ollama (lokal)"
        case .openAI:   return "OpenAI API"
        }
    }

    /// Provider die im Anbieter-Picker auswählbar sind (ohne .disabled)
    public static let activeProviders: [LLMProvider] = [.ollama, .openAI]
}
