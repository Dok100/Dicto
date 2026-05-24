import Foundation

/// Welcher LLM-Anbieter für die Textglättung genutzt wird.
public enum LLMProvider: String, CaseIterable {
    case ollama = "ollama"
    case openAI = "openai"

    public var label: String {
        switch self {
        case .ollama: return "Ollama (lokal)"
        case .openAI: return "OpenAI API"
        }
    }
}
