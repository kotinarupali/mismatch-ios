import Foundation

struct ScoreEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let playerId: UUID
    let reason: ScoreReason
    let points: Int

    init(id: UUID = UUID(), playerId: UUID, reason: ScoreReason) {
        self.id = id
        self.playerId = playerId
        self.reason = reason
        self.points = reason.points
    }
}

struct SessionScoreRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let avatarColor: AvatarColor
    let sessionScore: Int
    let roundPoints: Int
    let isHost: Bool
    let rank: Int
}
