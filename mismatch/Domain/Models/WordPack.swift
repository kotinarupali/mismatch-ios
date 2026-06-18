import Foundation

struct WordPack: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let displayName: String
    let pairs: [WordPair]
    let isBuiltIn: Bool
}
