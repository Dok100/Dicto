import Foundation

final class OllamaPostProcessor: TextPostProcessor {
    private let url: URL
    private let model: String
    private let systemPrompt: String

    init(baseURL: String, model: String, systemPrompt: String) {
        self.url = URL(string: "\(baseURL)/api/chat")!
        self.model = model
        self.systemPrompt = systemPrompt
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
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": "<diktat>\(text)</diktat>"
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
