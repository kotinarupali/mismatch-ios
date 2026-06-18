import Foundation

@MainActor
@Observable
final class GameSessionStore {
    private(set) var currentSession: GameSession?

    private let roleAssigner = RoleAssigner()

    var hasActiveSession: Bool { currentSession != nil }

    func createSession(settings: GameSettings = .default) {
        currentSession = GameSession(settings: settings)
    }

    func updateSettings(_ settings: GameSettings) {
        guard var session = currentSession else { return }
        session.settings = settings
        currentSession = session
    }

    func setPlayers(_ players: [PlayerSlot]) {
        guard var session = currentSession else { return }
        session.players = players
        currentSession = session
    }

    func updateState(_ state: GameState) {
        guard var session = currentSession else { return }
        session.state = state
        currentSession = session
    }

    func distributeRoles(wordPair: WordPair) throws {
        guard var session = currentSession else { return }
        let assigned = try roleAssigner.assign(
            players: session.players,
            wordPair: wordPair,
            settings: session.settings
        )
        session.players = assigned
        session.state = .distributing
        let round = Round(index: session.rounds.count, wordPairId: wordPair.id)
        session.rounds.append(round)
        session.currentRoundIndex = session.rounds.count - 1
        currentSession = session
    }

    func markCardOpened(playerId: UUID) {
        guard var session = currentSession else { return }
        guard let index = session.players.firstIndex(where: { $0.id == playerId }) else { return }
        session.players[index].hasOpenedCard = true
        currentSession = session
    }

    func allCardsOpened() -> Bool {
        currentSession?.players.allSatisfy(\.hasOpenedCard) ?? false
    }

    func passThePhoneOrder() -> [PlayerSlot] {
        guard let session = currentSession else { return [] }
        var players = session.players
        if let hostIndex = players.firstIndex(where: \.isHost) {
            let host = players.remove(at: hostIndex)
            players.append(host)
        }
        return players
    }

    func updatePlayerCardURL(playerId: UUID, token: String, url: String) {
        guard var session = currentSession else { return }
        guard let index = session.players.firstIndex(where: { $0.id == playerId }) else { return }
        session.players[index].cardToken = token
        session.players[index].cardURL = url
        currentSession = session
    }

    func startDiscussion() {
        updateState(.discussing)
    }

    func eliminate(playerId: UUID) {
        guard var session = currentSession else { return }
        guard let playerIndex = session.players.firstIndex(where: { $0.id == playerId }) else { return }

        session.players[playerIndex].isEliminated = true
        let eliminated = session.players[playerIndex]
        let outcome = WinConditionEvaluator.evaluate(eliminatedPlayer: eliminated)

        if session.currentRoundIndex < session.rounds.count {
            session.rounds[session.currentRoundIndex].eliminatedPlayerId = playerId
            session.rounds[session.currentRoundIndex].outcome = outcome
        }

        session.state = .revealing
        currentSession = session
    }

    func resetRoundForPlayAgain() {
        guard var session = currentSession else { return }
        session.state = .lobby
        session.rounds = []
        session.currentRoundIndex = 0
        session.players = session.players.map { player in
            var updated = player
            updated.assignment = nil
            updated.hasOpenedCard = false
            updated.isEliminated = false
            updated.cardToken = nil
            updated.cardURL = nil
            return updated
        }
        currentSession = session
    }

    func reset() {
        currentSession = nil
    }

    var currentRound: Round? {
        guard let session = currentSession,
              session.currentRoundIndex < session.rounds.count else { return nil }
        return session.rounds[session.currentRoundIndex]
    }

    var eliminatedPlayer: PlayerSlot? {
        guard let session = currentSession,
              let round = currentRound,
              let id = round.eliminatedPlayerId else { return nil }
        return session.players.first { $0.id == id }
    }

    var roundOutcome: RoundOutcome? {
        currentRound?.outcome
    }
}
