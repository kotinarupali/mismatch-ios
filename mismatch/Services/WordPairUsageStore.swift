import Foundation

struct WordPairStats: Equatable, Sendable {
    let used: Int
    let remaining: Int
    let total: Int
}

final class WordPairUsageStore: Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func usedPairIds(packId: String) -> Set<String> {
        Set(defaults.stringArray(forKey: storageKey(packId: packId)) ?? [])
    }

    func markUsed(_ pairId: String, packId: String) {
        var used = usedPairIds(packId: packId)
        used.insert(pairId)
        defaults.set(Array(used), forKey: storageKey(packId: packId))
    }

    func reset(packId: String) {
        defaults.removeObject(forKey: storageKey(packId: packId))
    }

    func resetAll() {
        let prefix = UserDefaultsKeys.usedWordPairIdsPrefix
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            defaults.removeObject(forKey: key)
        }
    }

    func stats(totalPairs: Int, packId: String) -> WordPairStats {
        let usedCount = usedPairIds(packId: packId).count
        let clampedUsed = min(usedCount, totalPairs)
        return WordPairStats(
            used: clampedUsed,
            remaining: max(0, totalPairs - clampedUsed),
            total: totalPairs
        )
    }

    private func storageKey(packId: String) -> String {
        "usedWordPairIds_\(packId)"
    }
}
