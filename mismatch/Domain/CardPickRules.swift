import Foundation

enum CardPickRules {
    static let minimumFaceDownCards = 3
    static let maximumFaceDownCards = 6

    /// Cosmetic pick grid size — scales with player count, capped at 6.
    static func faceDownCardCount(playerCount: Int) -> Int {
        min(maximumFaceDownCards, max(minimumFaceDownCards, playerCount))
    }
}
