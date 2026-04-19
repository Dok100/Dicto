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
                    "content": "Du bist ein Textkorrektur-Assistent für diktierten deutschen Text. Füge korrekte Satzzeichen ein, entferne Füllwörter (ähm, äh, hm, also) und verbessere die Lesbarkeit. Antworte NUR mit dem korrigierten Text, ohne Erklärungen."
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
