import Foundation

struct Round: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let index: Int
    var eliminatedPlayerId: UUID?
    var outcome: RoundOutcome?
    var wordPairId: String?

    init(
        id: UUID = UUID(),
        index: Int,
        eliminatedPlayerId: UUID? = nil,
        outcome: RoundOutcome? = nil,
        wordPairId: String? = nil
    ) {
        self.id = id
        self.index = index
        self.eliminatedPlayerId = eliminatedPlayerId
        self.outcome = outcome
        self.wordPairId = wordPairId
    }
}
