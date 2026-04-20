import Foundation

final class AppSettings: ObservableObject {
    @Published var ollamaEnabled: Bool {
        didSet { UserDefaults.standard.set(ollamaEnabled, forKey: "ollamaEnabled") }
    }
    @Published var ollamaBaseURL: String {
        didSet { UserDefaults.standard.set(ollamaBaseURL, forKey: "ollamaBaseURL") }
    }
    @Published var ollamaModel: String {
        didSet { UserDefaults.standard.set(ollamaModel, forKey: "ollamaModel") }
    }
    @Published var ollamaPrompt: String {
        didSet { UserDefaults.standard.set(ollamaPrompt, forKey: "ollamaPrompt") }
    }

    init() {
        let d = UserDefaults.standard
        ollamaEnabled = d.object(forKey: "ollamaEnabled") as? Bool ?? true
        ollamaBaseURL = d.string(forKey: "ollamaBaseURL") ?? "http://localhost:11434"
        ollamaModel   = d.string(forKey: "ollamaModel")   ?? "glm4"
        ollamaPrompt  = d.string(forKey: "ollamaPrompt")  ?? AppSettings.defaultPrompt
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
