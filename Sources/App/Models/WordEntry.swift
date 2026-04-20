import Foundation

public struct WordEntry: Codable, Identifiable {
    public var id = UUID()
    public var wrong: String
    public var correct: String
}
