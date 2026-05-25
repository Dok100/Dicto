/// Zentraler Einstiegspunkt für die LLM-Stream-Erstellung.
///
/// AppState fragt hier nach dem passenden Stream – welcher konkrete Processor
/// gebaut wird, entscheidet allein die Factory. Neuen Provider ergänzen:
/// nur diese Datei ändern, AppState bleibt unberührt.
enum LLMProcessorFactory {

    // MARK: – Diktat-Glättung

    /// Erstellt einen Stream der `text` mit dem konfigurierten Provider glättet.
    /// - Throws: `DictoError` bei ungültiger Konfiguration (z.B. fehlendem API-Key)
    /// - Precondition: `settings.llmProvider != .disabled`
    static func dictationStream(
        settings: AppSettings,
        systemPrompt: String,
        text: String
    ) throws -> AsyncThrowingStream<String, Error> {
        switch settings.llmProvider {
        case .disabled:
            preconditionFailure("dictationStream darf nicht mit .disabled aufgerufen werden")
        case .ollama:
            return try OllamaPostProcessor(
                baseURL: settings.ollamaBaseURL,
                model: settings.ollamaModel,
                systemPrompt: systemPrompt
            ).streamProcess(text: text)
        case .openAI:
            return try OpenAIPostProcessor(
                baseURL: settings.openAIBaseURL,
                apiKey: settings.openAIApiKey,
                model: settings.openAIModel,
                systemPrompt: systemPrompt
            ).streamProcess(text: text)
        }
    }

    // MARK: – Transform

    /// Erstellt einen Stream der `original` anhand von `command` umformt.
    /// - Throws: `DictoError` bei ungültiger Konfiguration
    /// - Precondition: `settings.llmProvider != .disabled`
    static func transformStream(
        settings: AppSettings,
        original: String,
        command: String
    ) throws -> AsyncThrowingStream<String, Error> {
        switch settings.llmProvider {
        case .disabled:
            preconditionFailure("transformStream darf nicht mit .disabled aufgerufen werden")
        case .ollama:
            return try OllamaTransformProcessor(
                baseURL: settings.ollamaBaseURL,
                model: settings.ollamaModel
            ).streamProcess(original: original, command: command)
        case .openAI:
            return try OpenAITransformProcessor(
                baseURL: settings.openAIBaseURL,
                apiKey: settings.openAIApiKey,
                model: settings.openAIModel
            ).streamProcess(original: original, command: command)
        }
    }
}
