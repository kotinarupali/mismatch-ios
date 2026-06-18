import Foundation

struct RoleCounts: Equatable, Sendable {
    let insider: Int
    let mismatch: Int
    let ghost: Int

    var total: Int { insider + mismatch + ghost }
}

enum RoleDistributionTable {
    /// Returns role counts for the given player count and ghost setting.
    /// When ghost is disabled, ghost slots become insiders.
    static func counts(playerCount: Int, ghostEnabled: Bool) -> RoleCounts {
        let mismatch = mismatchCount(for: playerCount)
        let ghost = ghostEnabled ? ghostCount(for: playerCount) : 0
        let insider = max(0, playerCount - mismatch - ghost)
        return RoleCounts(insider: insider, mismatch: mismatch, ghost: ghost)
    }

    private static func mismatchCount(for playerCount: Int) -> Int {
        switch playerCount {
        case 4...9: 1
        case 10...16: 2
        default: 1
        }
    }

    private static func ghostCount(for playerCount: Int) -> Int {
        switch playerCount {
        case 4...5: 0
        case 6...13: 1
        case 14...16: 2
        default: 0
        }
    }
}
