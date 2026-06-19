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
    var sharedJoinURL: String?
    var joinSessionToken: String?
    var cloudHostKey: String?
    var cardDeliveryBackend: CardDeliveryBackend
    var sessionEndScoreEvents: [ScoreEvent]
    var sessionWinBonusesApplied: Bool
    var gamesPlayedCount: Int
    /// Number of completed games whose win/streak/points have been synced to profiles.
    var profileStatsSyncedGamesCount: Int
    var lastCompletedGamePointsByPlayer: [UUID: Int]
    var summaryScoreByPlayer: [UUID: Int]
    var summaryLastGamePointsByPlayer: [UUID: Int]

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
        forcedSessionOutcome: RoundOutcome? = nil,
        sharedJoinURL: String? = nil,
        joinSessionToken: String? = nil,
        cloudHostKey: String? = nil,
        cardDeliveryBackend: CardDeliveryBackend = .local,
        sessionEndScoreEvents: [ScoreEvent] = [],
        sessionWinBonusesApplied: Bool = false,
        gamesPlayedCount: Int = 0,
        profileStatsSyncedGamesCount: Int = 0,
        lastCompletedGamePointsByPlayer: [UUID: Int] = [:],
        summaryScoreByPlayer: [UUID: Int] = [:],
        summaryLastGamePointsByPlayer: [UUID: Int] = [:]
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
        self.sharedJoinURL = sharedJoinURL
        self.joinSessionToken = joinSessionToken
        self.cloudHostKey = cloudHostKey
        self.cardDeliveryBackend = cardDeliveryBackend
        self.sessionEndScoreEvents = sessionEndScoreEvents
        self.sessionWinBonusesApplied = sessionWinBonusesApplied
        self.gamesPlayedCount = gamesPlayedCount
        self.profileStatsSyncedGamesCount = profileStatsSyncedGamesCount
        self.lastCompletedGamePointsByPlayer = lastCompletedGamePointsByPlayer
        self.summaryScoreByPlayer = summaryScoreByPlayer
        self.summaryLastGamePointsByPlayer = summaryLastGamePointsByPlayer
    }

    var playerCount: Int { players.count }
    var canStartGame: Bool { players.count >= 3 }
}
