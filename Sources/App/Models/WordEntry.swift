import Foundation

struct WordEntry: Codable, Identifiable {
    var id = UUID()
    var wrong: String
    var correct: String
}
