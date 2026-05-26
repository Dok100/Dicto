/// Zentrale Sammlung aller persistenten Speicher-Schlüssel.
///
/// Verhindert Tippfehler und macht Umbenennungen sicher –
/// der Compiler meldet unbekannte Keys sofort.
enum StorageKey {
    /// UserDefaults-Keys (Einstellungen, Zustand, Historie)
    enum Defaults {
        // MARK: Ollama

        /// Legacy-Key – nur noch für einmalige Migration zu `llmProvider` genutzt.
        static let ollamaEnabledLegacy = "ollamaEnabled"
        static let ollamaBaseURL = "ollamaBaseURL"
        static let ollamaModel = "ollamaModel"
        static let ollamaPrompt = "ollamaPrompt"

        // MARK: Transkription

        static let transcriptionEngine = "transcriptionEngine"
        static let whisperModel = "whisperModel"
        static let whisperLanguage = "whisperLanguage"

        // MARK: UI / Verhalten

        static let previewEnabled = "previewEnabled"
        static let soundFeedbackEnabled = "soundFeedbackEnabled"

        // MARK: Stile & Shortcuts

        static let customStyles = "customStyles"
        static let dictationShortcut = "dictationShortcut"
        static let transformShortcut = "transformShortcut"
        static let dictationStyle = "dictationStyle"

        // MARK: OpenAI / LLM

        static let llmProvider = "llmProvider"
        static let openAIModel = "openAIModel"
        static let openAIBaseURL = "openAIBaseURL"

        // MARK: Onboarding

        static let onboardingCompleted = "onboardingCompleted"

        // MARK: Daten-Services

        static let dictationHistory = "dictationHistory"
        static let dictionaryEntries = "dictionaryEntries"
    }

    /// Keychain-Keys (vertrauliche Zugangsdaten)
    enum Keychain {
        static let openAIApiKey = "openAIApiKey"
    }
}
