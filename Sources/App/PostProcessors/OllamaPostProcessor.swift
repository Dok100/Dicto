import Foundation

final class OllamaPostProcessor: TextPostProcessor {
    private let url: URL
    private let model: String

    init(baseURL: String = "http://localhost:11434", model: String = "glm4") {
        self.url = URL(string: "\(baseURL)/api/chat")!
        self.model = model
    }

    func process(text: String) async -> String {
        do {
            return try await smooth(text: text)
        } catch {
            return text  // Fallback: Originaltext bei jedem Fehler
        }
    }

    private func smooth(text: String) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                [
                    "role": "system",
                    "content": """
                        Du bist ein Textglätter für deutsche Diktate. Deine Aufgabe:
                        - Entferne Füllwörter: "äh", "ähm", "also", "halt", "irgendwie", "sozusagen", "quasi", "genau", doppelte Sätze, Selbstkorrekturen
                        - Glätte den Satzbau, ohne Bedeutung oder Tonalität zu verändern
                        - Behalte den Sprachstil des Sprechers bei (förmlich bleibt förmlich, locker bleibt locker)
                        - Füge KEINE neuen Inhalte, Fakten oder Interpretationen hinzu
                        - Gib ausschließlich den geglätteten Text zurück, keine Kommentare, keine Einleitung, keine Markdown-Formatierung
                        - Wenn der Eingabetext bereits sauber ist, gib ihn unverändert zurück
                        """
                ],
                [
                    "role": "user",
                    "content": text
                ]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
        let cleaned = response.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? text : cleaned
    }
}

private struct OllamaChatResponse: Decodable {
    struct Message: Decodable { let content: String }
    let message: Message
}
