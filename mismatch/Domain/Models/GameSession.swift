import Foundation

struct GameSession: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    var settings: GameSettings
    var state: GameState
    var players: [PlayerSlot]
    var rounds: [Round]
    var currentRoundIndex: Int
    var passOrderPlayerIds: [UUID]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        settings: GameSettings = .default,
        state: GameState = .lobby,
        players: [PlayerSlot] = [],
        rounds: [Round] = [],
        currentRoundIndex: Int = 0,
        passOrderPlayerIds: [UUID] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.settings = settings
        self.state = state
        self.players = players
        self.rounds = rounds
        self.currentRoundIndex = currentRoundIndex
        self.passOrderPlayerIds = passOrderPlayerIds
    }

    var playerCount: Int { players.count }
    var canStartGame: Bool { players.count >= 3 }
}
