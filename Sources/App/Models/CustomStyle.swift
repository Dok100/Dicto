import Foundation

/// Ein nutzerdefinierter Diktat-Stil mit eigenem System-Prompt.
public struct CustomStyle: Codable, Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var prompt: String

    public init(id: UUID = UUID(), name: String, prompt: String) {
        self.id = id
        self.name = name
        self.prompt = prompt
    }
}
