import Foundation

struct RoleCounts: Equatable, Sendable {
    let insider: Int
    let mismatch: Int
    let ghost: Int

    var total: Int { insider + mismatch + ghost }
}

enum RoleDistributionTable {
    /// Minimum players before Ghost slots can appear in the distribution table.
    static let minimumPlayerCountForGhost = 4

    /// Returns role counts for the given player count and ghost setting.
    /// When ghost is disabled, ghost slots become insiders.
    ///
    /// Tuned for livelier party rounds — roughly one-third to half the table are outsiders at larger sizes.
    static func counts(playerCount: Int, ghostEnabled: Bool) -> RoleCounts {
        let mismatch = mismatchCount(for: playerCount)
        let ghost = ghostEnabled ? ghostCount(for: playerCount) : 0
        let insider = max(0, playerCount - mismatch - ghost)
        return RoleCounts(insider: insider, mismatch: mismatch, ghost: ghost)
    }

    private static func mismatchCount(for playerCount: Int) -> Int {
        switch playerCount {
        case 3: 1
        case 4: 1
        case 5...6: 2
        case 7...8: 2
        case 9...10: 3
        case 11...12: 3
        case 13...15: 4
        default: max(4, playerCount / 4)
        }
    }

    private static func ghostCount(for playerCount: Int) -> Int {
        switch playerCount {
        case ..<4: 0
        case 4...5: 1
        case 6...8: 2
        case 9...11: 2
        case 12...14: 3
        default: max(3, playerCount / 5)
        }
    }
}
