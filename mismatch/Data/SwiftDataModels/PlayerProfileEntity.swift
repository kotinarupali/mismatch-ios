import Foundation
import SwiftData

@Model
final class PlayerProfileEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarColorRaw: String
    var createdAt: Date
    var gamesPlayed: Int
    var winsAsInsider: Int
    var winsAsMismatch: Int
    var winsAsGhost: Int
    var totalPoints: Int
    var currentStreak: Int
    var bestStreak: Int

    init(
        id: UUID = UUID(),
        name: String,
        avatarColorRaw: String,
        createdAt: Date = Date(),
        gamesPlayed: Int = 0,
        winsAsInsider: Int = 0,
        winsAsMismatch: Int = 0,
        winsAsGhost: Int = 0,
        totalPoints: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0
    ) {
        self.id = id
        self.name = name
        self.avatarColorRaw = avatarColorRaw
        self.createdAt = createdAt
        self.gamesPlayed = gamesPlayed
        self.winsAsInsider = winsAsInsider
        self.winsAsMismatch = winsAsMismatch
        self.winsAsGhost = winsAsGhost
        self.totalPoints = totalPoints
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
    }
}
