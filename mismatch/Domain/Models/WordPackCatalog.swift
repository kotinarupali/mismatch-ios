import Foundation

struct WordPackCatalogEntry: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let displayName: String
    let resourceName: String
}

struct WordPackCatalog: Codable, Equatable, Sendable {
    let packs: [WordPackCatalogEntry]
}

struct WordPackSummary: Identifiable, Equatable, Sendable {
    let id: String
    let displayName: String
    let stats: WordPairStats
    var isSelected: Bool
}

struct WordPairSelection: Equatable, Sendable {
    let packId: String
    let pair: WordPair
}
