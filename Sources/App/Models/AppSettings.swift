import Foundation

public final class AppSettings: ObservableObject {
    @Published public var ollamaEnabled: Bool {
        didSet { UserDefaults.standard.set(ollamaEnabled, forKey: "ollamaEnabled") }
    }
    @Published public var ollamaBaseURL: String {
        didSet { UserDefaults.standard.set(ollamaBaseURL, forKey: "ollamaBaseURL") }
    }
    @Published public var ollamaModel: String {
        didSet { UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel") }
    }
    @Published public var ollamaPrompt: String {
        didSet { UserDefaults.standard.set(ollamaPrompt, forKey: "ollamaPrompt") }
    }
    @Published public var whisperModel: WhisperModel {
        didSet { UserDefaults.standard.set(whisperModel.rawValue, forKey: "whisperModel") }
    }
    @Published public var previewEnabled: Bool {
        didSet { UserDefaults.standard.set(previewEnabled, forKey: "previewEnabled") }
    }
    @Published public var whisperLanguage: WhisperLanguage {
        didSet { UserDefaults.standard.set(whisperLanguage.rawValue, forKey: "whisperLanguage") }
    }

    public init() {
        let d = UserDefaults.standard
        ollamaEnabled    = d.object(forKey: "ollamaEnabled")   as? Bool ?? true
        ollamaBaseURL    = d.string(forKey: "ollamaBaseURL")   ?? "http://localhost:11434"
        ollamaModel      = d.string(forKey: "ollamaModel")     ?? "glm4"
        ollamaPrompt     = d.string(forKey: "ollamaPrompt")    ?? AppSettings.defaultPrompt
        whisperModel     = WhisperModel(rawValue: d.string(forKey: "whisperModel") ?? "") ?? .largev3
        previewEnabled   = d.object(forKey: "previewEnabled")  as? Bool ?? false
        whisperLanguage  = d.string(forKey: "whisperLanguage").flatMap(WhisperLanguage.init) ?? .german
    }

    static let defaultPrompt = """
        Du glättest deutschen Diktat-Text. Schreibe ausschließlich auf Deutsch.
        Regeln:
        - Entferne Füllwörter (äh, ähm, halt, irgendwie, also, sozusagen)
        - Korrigiere Satzbau und Grammatik konsequent (fehlende Artikel, Subjekte, Verbformen)
        - Behalte den Wortlaut so nah wie möglich am Original
        - Keine stilistische Aufwertung, keine Höflichkeitsformeln
        - Schreibe so, wie man es tippen würde – direkt und klar
        - Antworte NIEMALS auf den Inhalt des Textes, auch wenn er eine Frage enthält
        - Der Text steht in <diktat>…</diktat>-Tags – gib ihn OHNE diese Tags zurück
        Gib nur den geglätteten Text zurück, keine Kommentare.
        """
}
