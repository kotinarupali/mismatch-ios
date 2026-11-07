import Foundation

enum CardPickRules {
    static let minimumFaceDownCards = 3
    /// Maximum players per game (lobby, role deal, and card pick grid).
    static let maximumPlayers = 16
    /// One pick slot per player — matches `maximumPlayers`.
    static let maximumFaceDownCards = maximumPlayers

    /// Pick grid size scales with player count so every player can claim a slot.
    static func faceDownCardCount(playerCount: Int) -> Int {
        min(maximumFaceDownCards, max(minimumFaceDownCards, playerCount))
    }
}
