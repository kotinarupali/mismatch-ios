import Foundation

struct RoleCounts: Equatable, Sendable {
    let insider: Int
    let mismatch: Int
    let ghost: Int

    var total: Int { insider + mismatch + ghost }
}

enum RoleDistributionTable {
    /// Minimum players before Ghost slots can appear in the distribution table.
    static let minimumPlayerCountForGhost = 5

    /// Returns role counts for the given player count and ghost setting.
    /// When ghost is disabled, ghost slots become insiders.
    ///
    /// Insiders are always the majority — outsiders never outnumber them.
    static func counts(playerCount: Int, ghostEnabled: Bool) -> RoleCounts {
        let mismatch = mismatchCount(for: playerCount)
        let ghost = ghostEnabled ? ghostCount(for: playerCount) : 0
        let insider = max(0, playerCount - mismatch - ghost)
        return RoleCounts(insider: insider, mismatch: mismatch, ghost: ghost)
    }

    private static func mismatchCount(for playerCount: Int) -> Int {
        switch playerCount {
        case 3, 4: return 1
        case 5...6: return 1
        case 7...8: return 2
        case 9...12: return 3
        case 13...14: return 4
        case 15...16: return 4
        default:
            guard playerCount > 16 else { return 1 }
            return max(1, playerCount - insiderCount(for: playerCount) - ghostCount(for: playerCount))
        }
    }

    private static func ghostCount(for playerCount: Int) -> Int {
        switch playerCount {
        case ..<5: return 0
        case 5...10: return 1
        case 11...16: return 2
        default:
            guard playerCount > 16 else { return 0 }
            return 1 + (playerCount - 5) / 6
        }
    }

    private static func insiderCount(for playerCount: Int) -> Int {
        switch playerCount {
        case 3: return 2
        case 4: return 3
        case 5...: return 3 + (playerCount - 4) / 2
        default: return 0
        }
    }
}
