import Foundation

struct PlayerPersonaCard: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let avatarColor: AvatarColor
    let title: String
    let subtitle: String
    let symbolName: String
    let accentHex: PersonaAccent
}

enum PersonaAccent: String, Sendable {
    case gold
    case coral
    case mint
    case violet
    case sky
    case rose
    case amber

    var symbolName: String {
        switch self {
        case .gold: "crown.fill"
        case .coral: "flame.fill"
        case .mint: "leaf.fill"
        case .violet: "moon.stars.fill"
        case .sky: "sparkles"
        case .rose: "heart.fill"
        case .amber: "sun.max.fill"
        }
    }
}

struct PlayerSessionStats: Sendable {
    let playerId: UUID
    let displayName: String
    let avatarColor: AvatarColor
    let role: Role?
    let sessionScore: Int
    let roundsSurvived: Int
    let hasWinBonus: Bool
    let hasGhostGuess: Bool
    let eliminationRoundIndex: Int?
    let isHost: Bool
}
