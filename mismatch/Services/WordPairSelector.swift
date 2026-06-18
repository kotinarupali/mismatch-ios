import Foundation

enum WordPairSelectorError: Error {
    case noPairsAvailable
    case noPacksSelected
}

struct WordPairSelector: Sendable {
    let loader: WordPackLoader
    let usageStore: WordPairUsageStore

    func stats(packId: String) throws -> WordPairStats {
        let pack = try loader.loadBuiltIn(packId: packId)
        return usageStore.stats(totalPairs: pack.pairs.count, packId: packId)
    }

    func stats(for packIds: [String]) throws -> [WordPackSummary] {
        let selected = Set(packIds)
        return try loader.summaries(selectedPackIds: selected) { packId, total in
            usageStore.stats(totalPairs: total, packId: packId)
        }
    }

    func nextPair(packIds: [String]) throws -> WordPairSelection {
        let normalized = normalizedPackIds(packIds)
        guard !normalized.isEmpty else { throw WordPairSelectorError.noPacksSelected }

        var available: [WordPairSelection] = []

        for packId in normalized {
            let pack = try loader.loadBuiltIn(packId: packId)
            guard !pack.pairs.isEmpty else { continue }

            let used = usageStore.usedPairIds(packId: packId)
            var packAvailable = pack.pairs.filter { !used.contains($0.id) }

            if packAvailable.isEmpty {
                usageStore.reset(packId: packId)
                packAvailable = pack.pairs
            }

            available.append(contentsOf: packAvailable.map { WordPairSelection(packId: packId, pair: $0) })
        }

        guard !available.isEmpty else { throw WordPairSelectorError.noPairsAvailable }
        return try CryptoRandom.shuffled(available)[0]
    }

    func markUsed(_ selection: WordPairSelection) {
        usageStore.markUsed(selection.pair.id, packId: selection.packId)
    }

    private func normalizedPackIds(_ packIds: [String]) -> [String] {
        var seen = Set<String>()
        return packIds.filter { seen.insert($0).inserted }
    }
}
