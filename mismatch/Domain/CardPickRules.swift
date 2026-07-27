import Foundation

enum CardPickRules {
    static let minimumFaceDownCards = 3
    /// One pick slot per player — matches the 16-player lobby cap.
    static let maximumFaceDownCards = 16

    /// Pick grid size scales with player count so every player can claim a slot.
    static func faceDownCardCount(playerCount: Int) -> Int {
        min(maximumFaceDownCards, max(minimumFaceDownCards, playerCount))
    }
}
