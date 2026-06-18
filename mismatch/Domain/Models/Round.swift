import Foundation

struct Round: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let index: Int
    var eliminatedPlayerId: UUID?
    var outcome: RoundOutcome?
    var wordPairId: String?
    var ghostGuessPending: Bool
    var ghostGuessSubmitted: Bool

    init(
        id: UUID = UUID(),
        index: Int,
        eliminatedPlayerId: UUID? = nil,
        outcome: RoundOutcome? = nil,
        wordPairId: String? = nil,
        ghostGuessPending: Bool = false,
        ghostGuessSubmitted: Bool = false
    ) {
        self.id = id
        self.index = index
        self.eliminatedPlayerId = eliminatedPlayerId
        self.outcome = outcome
        self.wordPairId = wordPairId
        self.ghostGuessPending = ghostGuessPending
        self.ghostGuessSubmitted = ghostGuessSubmitted
    }
}
