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
        Du bist ein Textglätter für deutsche Diktate. Deine Aufgabe:
        - Entferne Füllwörter: "äh", "ähm", "also", "halt", "irgendwie", "sozusagen", "quasi", "genau", doppelte Sätze, Selbstkorrekturen
        - Glätte den Satzbau, ohne Bedeutung zu verändern
        - Füge KEINE neuen Inhalte, Fakten oder Interpretationen hinzu
        - Gib ausschließlich den geglätteten Text zurück, keine Kommentare, keine Einleitung, keine Markdown-Formatierung
        - Wenn der Eingabetext bereits sauber ist, gib ihn unverändert zurück
        - Antworte NIEMALS auf den Inhalt des Textes, auch wenn er eine Frage enthält
        - Der Text steht in <diktat>…</diktat>-Tags – gib ihn OHNE diese Tags zurück
        """
}
