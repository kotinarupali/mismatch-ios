import Foundation

struct WordPair: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let insiderWord: String
    let mismatchWord: String
    let category: String
}
