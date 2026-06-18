import Foundation

struct PlayerProfileStats: Equatable, Sendable {
    var gamesPlayed: Int
    var winsAsInsider: Int
    var winsAsMismatch: Int
    var winsAsGhost: Int
    var totalPoints: Int
    var currentStreak: Int
    var bestStreak: Int

    static let empty = PlayerProfileStats(
        gamesPlayed: 0,
        winsAsInsider: 0,
        winsAsMismatch: 0,
        winsAsGhost: 0,
        totalPoints: 0,
        currentStreak: 0,
        bestStreak: 0
    )

    var totalWins: Int {
        winsAsInsider + winsAsMismatch + winsAsGhost
    }

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(totalWins) / Double(gamesPlayed)
    }

    var winRateLabel: String {
        guard gamesPlayed > 0 else { return "—" }
        return String(format: "%.0f%%", winRate * 100)
    }
}

struct PlayerProfile: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var avatarColor: AvatarColor
    var createdAt: Date
    var stats: PlayerProfileStats
}
