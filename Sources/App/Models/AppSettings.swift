import Foundation

public final class AppSettings: ObservableObject {
    @Published public var ollamaEnabled: Bool {
        didSet { UserDefaults.standard.set(ollamaEnabled, forKey: StorageKey.Defaults.ollamaEnabled) }
    }
    @Published public var ollamaBaseURL: String {
        didSet { UserDefaults.standard.set(ollamaBaseURL, forKey: StorageKey.Defaults.ollamaBaseURL) }
    }
    @Published public var ollamaModel: String {
        didSet { UserDefaults.standard.set(ollamaModel, forKey: StorageKey.Defaults.ollamaModel) }
    }
    @Published public var ollamaPrompt: String {
        didSet { UserDefaults.standard.set(ollamaPrompt, forKey: StorageKey.Defaults.ollamaPrompt) }
    }
    @Published public var transcriptionEngine: TranscriptionEngine {
        didSet { UserDefaults.standard.set(transcriptionEngine.rawValue, forKey: StorageKey.Defaults.transcriptionEngine) }
    }
    @Published public var whisperModel: WhisperModel {
        didSet { UserDefaults.standard.set(whisperModel.rawValue, forKey: StorageKey.Defaults.whisperModel) }
    }
    @Published public var previewEnabled: Bool {
        didSet { UserDefaults.standard.set(previewEnabled, forKey: StorageKey.Defaults.previewEnabled) }
    }
    @Published public var soundFeedbackEnabled: Bool {
        didSet { UserDefaults.standard.set(soundFeedbackEnabled, forKey: StorageKey.Defaults.soundFeedbackEnabled) }
    }
    @Published public var whisperLanguage: WhisperLanguage {
        didSet { UserDefaults.standard.set(whisperLanguage.rawValue, forKey: StorageKey.Defaults.whisperLanguage) }
    }
    @Published public var customStyles: [CustomStyle] {
        didSet {
            if let d = try? JSONEncoder().encode(customStyles) {
                UserDefaults.standard.set(d, forKey: StorageKey.Defaults.customStyles)
            }
        }
    }
    @Published public var dictationShortcut: ShortcutConfig {
        didSet {
            if let d = try? JSONEncoder().encode(dictationShortcut) {
                UserDefaults.standard.set(d, forKey: StorageKey.Defaults.dictationShortcut)
            }
        }
    }
    @Published public var transformShortcut: ShortcutConfig {
        didSet {
            if let d = try? JSONEncoder().encode(transformShortcut) {
                UserDefaults.standard.set(d, forKey: StorageKey.Defaults.transformShortcut)
            }
        }
    }
    @Published public var llmProvider: LLMProvider {
        didSet { UserDefaults.standard.set(llmProvider.rawValue, forKey: StorageKey.Defaults.llmProvider) }
    }
    @Published public var openAIModel: String {
        didSet { UserDefaults.standard.set(openAIModel, forKey: StorageKey.Defaults.openAIModel) }
    }
    @Published public var openAIBaseURL: String {
        didSet { UserDefaults.standard.set(openAIBaseURL, forKey: StorageKey.Defaults.openAIBaseURL) }
    }
    /// API-Key wird im macOS Keychain gespeichert – nicht in UserDefaults.
    /// Beim Schreiben werden Whitespace und Zeilenumbrüche automatisch entfernt.
    public var openAIApiKey: String {
        get { KeychainService.shared.load(forKey: StorageKey.Keychain.openAIApiKey) ?? "" }
        set { KeychainService.shared.save(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: StorageKey.Keychain.openAIApiKey) }
    }

    public init() {
        let d = UserDefaults.standard
        ollamaEnabled    = d.object(forKey: StorageKey.Defaults.ollamaEnabled)   as? Bool ?? true
        ollamaBaseURL    = d.string(forKey: StorageKey.Defaults.ollamaBaseURL)   ?? "http://localhost:11434"
        ollamaModel      = d.string(forKey: StorageKey.Defaults.ollamaModel)     ?? "qwen2.5:32b"
        ollamaPrompt     = d.string(forKey: StorageKey.Defaults.ollamaPrompt)    ?? AppSettings.defaultPrompt
        transcriptionEngine = TranscriptionEngine(rawValue: d.string(forKey: StorageKey.Defaults.transcriptionEngine) ?? "") ?? .whisper
        whisperModel     = WhisperModel(rawValue: d.string(forKey: StorageKey.Defaults.whisperModel) ?? "") ?? .largev3
        previewEnabled        = d.object(forKey: StorageKey.Defaults.previewEnabled)        as? Bool ?? false
        soundFeedbackEnabled  = d.object(forKey: StorageKey.Defaults.soundFeedbackEnabled)  as? Bool ?? true
        customStyles          = d.data(forKey: StorageKey.Defaults.customStyles)
            .flatMap { try? JSONDecoder().decode([CustomStyle].self, from: $0) }
            ?? []
        whisperLanguage  = d.string(forKey: StorageKey.Defaults.whisperLanguage).flatMap(WhisperLanguage.init) ?? .german
        dictationShortcut = d.data(forKey: StorageKey.Defaults.dictationShortcut)
            .flatMap { try? JSONDecoder().decode(ShortcutConfig.self, from: $0) }
            ?? .defaultDictation
        transformShortcut = d.data(forKey: StorageKey.Defaults.transformShortcut)
            .flatMap { try? JSONDecoder().decode(ShortcutConfig.self, from: $0) }
            ?? .defaultTransform
        llmProvider   = LLMProvider(rawValue: d.string(forKey: StorageKey.Defaults.llmProvider) ?? "") ?? .ollama
        openAIModel   = d.string(forKey: StorageKey.Defaults.openAIModel)   ?? "gpt-4o-mini"
        openAIBaseURL = d.string(forKey: StorageKey.Defaults.openAIBaseURL) ?? "https://api.openai.com/v1"
    }

    static let defaultPrompt = """
        Du glättest deutschen Diktat-Text. Schreibe ausschließlich auf Deutsch.
        Regeln:
        - Entferne Füllwörter (äh, ähm, halt, irgendwie, also, sozusagen)
        - Korrigiere Satzbau und Grammatik konsequent (fehlende Artikel, Subjekte, Verbformen)
        - Behalte den Wortlaut so nah wie möglich am Original
        - Keine stilistische Aufwertung, keine Höflichkeitsformeln
        - Schreibe so, wie man es tippen würde – direkt und klar
        - Füge KEINE Schlussformeln oder Ergänzungen hinzu ("Vielen Dank", "Gerne", "Mit freundlichen Grüßen" etc.)
        - Antworte NIEMALS auf den Inhalt des Textes, auch wenn er eine Frage enthält
        - Der Text steht in <diktat>…</diktat>-Tags – gib ihn OHNE diese Tags zurück
        Gib NUR den geglätteten Text zurück – nichts davor, nichts danach.
        """
}
