import Foundation

/// Führt Transform-Operationen über die OpenAI Chat-Completions-API aus.
final class OpenAITransformProcessor {
    private let url: URL
    private let apiKey: String
    private let model: String

    private static let systemPrompt = """
        Du führst Texttransformationen durch.
        Du bekommst einen Originaltext in <original>…</original>-Tags und einen Befehl in <befehl>…</befehl>-Tags.
        Führe den Befehl auf dem Originaltext aus.
        Antworte NUR mit dem transformierten Text – keine Erklärungen, keine Kommentare.
        Schreibe auf Deutsch, es sei denn der Befehl verlangt ausdrücklich eine andere Sprache.
        """

    init(baseURL: String, apiKey: String, model: String) throws {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw DictoError.openAIKeyMissing
        }
        guard let url = URL(string: "\(baseURL)/chat/completions"),
              let scheme = url.scheme, scheme == "http" || scheme == "https" else {
            throw DictoError.openAINotReachable
        }
        self.url = url
        self.apiKey = apiKey
        self.model = model
    }

    /// Liefert den transformierten Text Stück für Stück als AsyncThrowingStream.
    func streamProcess(original: String, command: String) -> AsyncThrowingStream<String, Error> {
        let request = makeRequest(original: original, command: command)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        throw DictoError.openAINotReachable
                    }
                    for try await line in asyncBytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let json = String(line.dropFirst(6))
                        if json.trimmingCharacters(in: .whitespaces) == "[DONE]" { break }
                        guard let data = json.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: data),
                              let content = chunk.choices.first?.delta.content,
                              !content.isEmpty else { continue }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch let e as DictoError {
                    continuation.finish(throwing: e)
                } catch let e as URLError {
                    continuation.finish(throwing: DictoError.fromOpenAI(e))
                } catch {
                    continuation.finish(throwing: DictoError.openAIUnknown)
                }
            }
        }
    }

    private func makeRequest(original: String, command: String) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)",  forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": [
                ["role": "system", "content": Self.systemPrompt],
                ["role": "user",   "content": "<original>\(original)</original>\n<befehl>\(command)</befehl>"]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
}

// MARK: – OpenAI SSE Chunk

private struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta
    }
    let choices: [Choice]
}
