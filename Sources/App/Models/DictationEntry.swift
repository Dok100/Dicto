import Foundation

public struct DictationEntry: Codable, Identifiable {
    public var id = UUID()
    public var text: String
    public var date: Date
}
