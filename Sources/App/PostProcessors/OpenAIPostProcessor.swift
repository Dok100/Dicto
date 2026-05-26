import Foundation

/// Sendet Text an die OpenAI Chat-Completions-API und liefert die Antwort als Stream.
/// Nutzt das Server-Sent-Events (SSE) Format: jede Zeile beginnt mit „data: ".
final class OpenAIPostProcessor {
    private let url: URL
    private let apiKey: String
    private let model: String
    private let systemPrompt: String

    init(baseURL: String, apiKey: String, model: String, systemPrompt: String) throws {
        // Whitespace + Zeilenumbrüche entfernen (1Password & Co. kopieren manchmal \n mit)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw DictoError.openAIKeyMissing
        }
        guard let url = URL(string: "\(baseURL)/chat/completions"),
              let scheme = url.scheme, scheme == "http" || scheme == "https" else
        {
            throw DictoError.openAINotReachable
        }
        self.url = url
        self.apiKey = trimmedKey
        self.model = model
        self.systemPrompt = systemPrompt
    }

    /// Liefert die KI-Antwort Stück für Stück als AsyncThrowingStream.
    func streamProcess(text: String) -> AsyncThrowingStream<String, Error> {
        let request = makeRequest(messages: [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "<diktat>\(text)</diktat>"]
        ])
        return parseSSEStream(request: request)
    }

    // MARK: – Privat

    private func makeRequest(messages: [[String: String]]) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": messages
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseSSEStream(request: URLRequest) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse {
                        switch http.statusCode {
                        case 200: break
                        case 401, 403: throw DictoError.openAIAuthFailed
                        default: throw DictoError.openAINotReachable
                        }
                    }
                    for try await line in asyncBytes.lines {
                        // SSE-Zeilen beginnen mit „data: "
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
}

// MARK: – OpenAI SSE Chunk

private struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable { let content: String? }
        let delta: Delta
    }

    let choices: [Choice]
}
