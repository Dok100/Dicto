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

    init(baseURL: String, model: String) throws {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw DictoError.ollamaNotReachable
        }
        self.url = url
        self.model = model
    }

    func process(original: String, command: String) async throws -> String {
        do {
            let result = try await transform(original: original, command: command)
            return result.isEmpty ? original : result
        } catch let e as DictoError {
            throw e
        } catch let e as URLError {
            throw DictoError.from(e)
        } catch {
            throw DictoError.ollamaUnknown
        }
    }

    private func transform(original: String, command: String) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user",   "content": "<original>\(original)</original>\n<befehl>\(command)</befehl>"]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OllamaTransformResponse.self, from: data)
        return response.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct OllamaTransformResponse: Decodable {
    struct Message: Decodable { let content: String }
    let message: Message
}
