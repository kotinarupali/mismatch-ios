import Foundation

struct CustomWordPair: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var insiderWord: String
    var mismatchWord: String
    var insiderCanonical: String
    var mismatchCanonical: String
    var category: String
    var playedAt: String?
    var isRemoved: Bool

    var names: [String] {
        [insiderWord, mismatchWord, insiderCanonical, mismatchCanonical]
    }

    var wordPair: WordPair {
        WordPair(id: id, insiderWord: insiderWord, mismatchWord: mismatchWord, category: category)
    }

    var isPlayable: Bool {
        !isRemoved && playedAt == nil
    }
}

struct CustomWordPack: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var prompt: String
    var title: String
    var createdAt: String?
    var pairs: [CustomWordPair]

    var selectionID: String { CustomPackID.make(id) }

    var playablePairs: [CustomWordPair] {
        pairs.filter(\.isPlayable)
    }

    var visiblePairs: [CustomWordPair] {
        pairs.filter { !$0.isRemoved }
    }

    var stats: WordPairStats {
        let visible = visiblePairs
        let used = visible.filter { $0.playedAt != nil }.count
        return WordPairStats(used: used, remaining: max(0, visible.count - used), total: visible.count)
    }
}

struct CustomPackLibrary: Codable, Equatable, Sendable {
    var packs: [CustomWordPack]
    var pendingPlayedPairIDs: [String]
    var pendingArchivedPackIDs: [String]

    static let empty = CustomPackLibrary(packs: [], pendingPlayedPairIDs: [], pendingArchivedPackIDs: [])

    private enum CodingKeys: String, CodingKey {
        case packs
        case pendingPlayedPairIDs
        case pendingArchivedPackIDs
    }

    init(packs: [CustomWordPack], pendingPlayedPairIDs: [String], pendingArchivedPackIDs: [String] = []) {
        self.packs = packs
        self.pendingPlayedPairIDs = pendingPlayedPairIDs
        self.pendingArchivedPackIDs = pendingArchivedPackIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        packs = try container.decodeIfPresent([CustomWordPack].self, forKey: .packs) ?? []
        pendingPlayedPairIDs = try container.decodeIfPresent([String].self, forKey: .pendingPlayedPairIDs) ?? []
        pendingArchivedPackIDs = try container.decodeIfPresent([String].self, forKey: .pendingArchivedPackIDs) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(packs, forKey: .packs)
        try container.encode(pendingPlayedPairIDs, forKey: .pendingPlayedPairIDs)
        try container.encode(pendingArchivedPackIDs, forKey: .pendingArchivedPackIDs)
    }
}
