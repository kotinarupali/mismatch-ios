import Foundation

struct GuestVoteTie: Equatable, Sendable {
    let tiedPlayerIds: [UUID]
    let voteCount: Int
}

enum GuestVoteTieDetector {
    /// Returns a tie when two or more active players share the highest guest vote count (> 0).
    static func detect(
        tallies: [UUID: Int],
        activePlayerIds: Set<UUID>
    ) -> GuestVoteTie? {
        let relevant = tallies.filter { activePlayerIds.contains($0.key) && $0.value > 0 }
        guard !relevant.isEmpty else { return nil }

        let maxCount = relevant.values.max() ?? 0
        let tied = relevant.filter { $0.value == maxCount }.map(\.key).sorted { $0.uuidString < $1.uuidString }
        guard tied.count >= 2 else { return nil }

        return GuestVoteTie(tiedPlayerIds: tied, voteCount: maxCount)
    }
}
