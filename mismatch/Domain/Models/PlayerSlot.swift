import Foundation

struct PlayerSlot: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var displayName: String
    var avatarColor: AvatarColor
    var isHost: Bool
    var assignment: RoleAssignment?
    var cardToken: String?
    var cardURL: String?
    var isEliminated: Bool
    var hasOpenedCard: Bool
    var pickedCardIndex: Int?

    init(
        id: UUID = UUID(),
        displayName: String,
        avatarColor: AvatarColor,
        isHost: Bool = false,
        assignment: RoleAssignment? = nil,
        cardToken: String? = nil,
        cardURL: String? = nil,
        isEliminated: Bool = false,
        hasOpenedCard: Bool = false,
        pickedCardIndex: Int? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarColor = avatarColor
        self.isHost = isHost
        self.assignment = assignment
        self.cardToken = cardToken
        self.cardURL = cardURL
        self.isEliminated = isEliminated
        self.hasOpenedCard = hasOpenedCard
        self.pickedCardIndex = pickedCardIndex
    }
}
