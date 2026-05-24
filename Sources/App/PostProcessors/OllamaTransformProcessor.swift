import Foundation

final class OllamaTransformProcessor {
    private let url: URL
    private let model: String

    private static let systemPrompt = """
        Du führst Texttransformationen durch.
        Du bekommst einen Originaltext in <original>…</original>-Tags und einen Befehl in <befehl>…</befehl>-Tags.
        Führe den Befehl auf dem Originaltext aus.
        Antworte NUR mit dem transformierten Text – keine Erklärungen, keine Kommentare.
        Schreibe auf Deutsch, es sei denn der Befehl verlangt ausdrücklich eine andere Sprache.
        """

    init(baseURL: String, model: String) {
        self.url = URL(string: "\(baseURL)/api/chat")!
        self.model = model
    }

    func process(original: String, command: String) async -> String {
        do {
            return try await transform(original: original, command: command)
        } catch let error as URLError where error.code == .timedOut {
            return "⚠ Ollama Timeout – Modell zu langsam (>\(Int(timeoutSeconds))s). Versuche es erneut oder wähle ein kleineres Modell."
        } catch {
            return "⚠ Ollama Fehler: \(error.localizedDescription)"
        }
    }

    private let timeoutSeconds: Double = 120

    private func transform(original: String, command: String) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: timeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user", "content": "<original>\(original)</original>\n<befehl>\(command)</befehl>"]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaTransformResponse.self, from: data)
        let cleaned = response.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? original : cleaned
    }
}

private struct OllamaTransformResponse: Decodable {
    struct Message: Decodable { let content: String }
    let message: Message
}
