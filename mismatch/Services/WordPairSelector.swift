import Foundation

enum WordPairSelectorError: Error {
    case noPairsAvailable
}

struct WordPairSelector: Sendable {
    let loader: WordPackLoader
    let usageStore: WordPairUsageStore

    func stats(packId: String = "general") throws -> WordPairStats {
        let pack = try loader.loadBuiltIn(packId: packId)
        return usageStore.stats(totalPairs: pack.pairs.count, packId: packId)
    }

    func nextPair(packId: String = "general") throws -> WordPair {
        let pack = try loader.loadBuiltIn(packId: packId)
        guard !pack.pairs.isEmpty else { throw WordPairSelectorError.noPairsAvailable }

        let used = usageStore.usedPairIds(packId: packId)
        var available = pack.pairs.filter { !used.contains($0.id) }

        if available.isEmpty {
            usageStore.reset(packId: packId)
            available = pack.pairs
        }

        return try CryptoRandom.shuffled(available)[0]
    }

    func markUsed(_ pair: WordPair, packId: String = "general") {
        usageStore.markUsed(pair.id, packId: packId)
    }
}
