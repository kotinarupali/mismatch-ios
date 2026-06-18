import Foundation

struct GameSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    var settings: GameSettings
    var state: GameState
    var players: [PlayerSlot]
    var rounds: [Round]
    var currentRoundIndex: Int
    var seatingOrderPlayerIds: [UUID]
    var passOrderPlayerIds: [UUID]
    var discussionStartPlayerId: UUID?
    var currentInsiderWord: String?
    var currentMismatchWord: String?
    var forcedSessionOutcome: RoundOutcome?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        settings: GameSettings = .default,
        state: GameState = .lobby,
        players: [PlayerSlot] = [],
        rounds: [Round] = [],
        currentRoundIndex: Int = 0,
        seatingOrderPlayerIds: [UUID] = [],
        passOrderPlayerIds: [UUID] = [],
        discussionStartPlayerId: UUID? = nil,
        currentInsiderWord: String? = nil,
        currentMismatchWord: String? = nil,
        forcedSessionOutcome: RoundOutcome? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.settings = settings
        self.state = state
        self.players = players
        self.rounds = rounds
        self.currentRoundIndex = currentRoundIndex
        self.seatingOrderPlayerIds = seatingOrderPlayerIds
        self.passOrderPlayerIds = passOrderPlayerIds
        self.discussionStartPlayerId = discussionStartPlayerId
        self.currentInsiderWord = currentInsiderWord
        self.currentMismatchWord = currentMismatchWord
        self.forcedSessionOutcome = forcedSessionOutcome
    }

    var playerCount: Int { players.count }
    var canStartGame: Bool { players.count >= 3 }
}
