import Foundation

struct PlayerRoleReveal: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let avatarColor: AvatarColor
    let role: Role
    let isEliminated: Bool
}
