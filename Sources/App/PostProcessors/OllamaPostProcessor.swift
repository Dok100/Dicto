import Foundation

final class OllamaPostProcessor {
    private let url: URL
    private let model: String
    private let systemPrompt: String

    init(baseURL: String, model: String, systemPrompt: String) throws {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw DictoError.ollamaNotReachable
        }
        self.url = url
        self.model = model
        self.systemPrompt = systemPrompt
    }

    /// Liefert die Antwort als AsyncThrowingStream – jeder Wert ist ein neues Textfragment.
    func streamProcess(text: String) -> AsyncThrowingStream<String, Error> {
        let request = makeRequest(text: text)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in asyncBytes.lines {
                        guard !line.isEmpty else { continue }
                        guard let data = line.data(using: .utf8),
                              let chunk = try? JSONDecoder().decode(OllamaStreamChunk.self, from: data) else { continue }
                        if !chunk.message.content.isEmpty {
                            continuation.yield(chunk.message.content)
                        }
                        if chunk.done { break }
                    }
                    continuation.finish()
                } catch let e as DictoError {
                    continuation.finish(throwing: e)
                } catch let e as URLError {
                    continuation.finish(throwing: DictoError.from(e))
                } catch {
                    continuation.finish(throwing: DictoError.ollamaUnknown)
                }
            }
        }
    }

    private func makeRequest(text: String) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 120)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "<diktat>\(text)</diktat>"]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
}

private struct OllamaStreamChunk: Decodable {
    struct Message: Decodable { let content: String }
    let message: Message
    let done: Bool
}
