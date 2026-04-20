import Foundation

struct DictationEntry: Codable, Identifiable {
    var id = UUID()
    var text: String
    var date: Date
}
