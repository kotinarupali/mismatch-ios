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
        if session.seatingOrderPlayerIds.isEmpty {
            session.seatingOrderPlayerIds = players.map(\.id)
        } else {
            let validIds = Set(players.map(\.id))
            session.seatingOrderPlayerIds = session.seatingOrderPlayerIds.filter { validIds.contains($0) }
            for player in players where !session.seatingOrderPlayerIds.contains(player.id) {
                session.seatingOrderPlayerIds.append(player.id)
            }
        }
        currentSession = session
    }

    func setSeatingOrder(_ playerIds: [UUID]) {
        guard var session = currentSession else { return }
        let validIds = Set(session.players.map(\.id))
        session.seatingOrderPlayerIds = playerIds.filter { validIds.contains($0) }
        currentSession = session
    }

    func seatingOrderPlayers() -> [PlayerSlot] {
        guard let session = currentSession else { return [] }
        return orderedPlayers(from: session.seatingOrderPlayerIds, in: session.players)
    }

    func updateState(_ state: GameState) {
        guard var session = currentSession else { return }
        session.state = state
        currentSession = session
    }

    func distributeRoles(wordPair: WordPair) throws {
        guard var session = currentSession else {
            throw GameSessionStoreError.noActiveSession
        }
        let assigned = try roleAssigner.assign(
            players: session.players,
            wordPair: wordPair,
            settings: session.settings
        )
        session.players = assigned
        session.state = .distributing
        let seatingIds = normalizedSeatingOrderIds(for: session)
        session.seatingOrderPlayerIds = seatingIds
        session.passOrderPlayerIds = try randomPassOrder(from: seatingIds)
        let round = Round(index: session.rounds.count, wordPairId: wordPair.id)
        session.rounds.append(round)
        session.currentRoundIndex = session.rounds.count - 1
        currentSession = session
    }

    func markCardOpened(playerId: UUID, cardIndex: Int) {
        guard var session = currentSession else { return }
        guard let index = session.players.firstIndex(where: { $0.id == playerId }) else { return }
        session.players[index].hasOpenedCard = true
        session.players[index].pickedCardIndex = cardIndex
        currentSession = session
    }

    func allCardsOpened() -> Bool {
        currentSession?.players.allSatisfy(\.hasOpenedCard) ?? false
    }

    func passThePhoneOrder() -> [PlayerSlot] {
        guard let session = currentSession else { return [] }
        return resolvePlayerOrder(
            ids: preferredPassOrderIds(in: session),
            in: session.players
        )
    }

    private func preferredPassOrderIds(in session: GameSession) -> [UUID] {
        if !session.passOrderPlayerIds.isEmpty {
            return session.passOrderPlayerIds
        }
        if !session.seatingOrderPlayerIds.isEmpty {
            return session.seatingOrderPlayerIds
        }
        return session.players.map(\.id)
    }

    func claimedCards() -> [ClaimedCard] {
        guard let session = currentSession else { return [] }
        return session.players.compactMap { player in
            guard player.hasOpenedCard, let index = player.pickedCardIndex else { return nil }
            let name = player.isHost ? "You" : player.displayName
            return ClaimedCard(index: index, playerName: name)
        }
    }

    func playersWithPickedCards() -> [PlayerSlot] {
        currentSession?.players.filter { $0.hasOpenedCard && $0.assignment != nil } ?? []
    }

    func remainingOutsiderCounts() -> (mismatch: Int, ghost: Int) {
        let active = currentSession?.players.filter { !$0.isEliminated } ?? []
        let mismatch = active.filter { $0.assignment?.role == .mismatch }.count
        let ghost = active.filter { $0.assignment?.role == .ghost }.count
        return (mismatch, ghost)
    }

    func updatePlayerCardURL(playerId: UUID, token: String, url: String) {
        guard var session = currentSession else { return }
        guard let index = session.players.firstIndex(where: { $0.id == playerId }) else { return }
        session.players[index].cardToken = token
        session.players[index].cardURL = url
        currentSession = session
    }

    func startDiscussion() {
        assignRandomDiscussionStarter()
        updateState(.discussing)
    }

    func eliminate(playerId: UUID) {
        guard var session = currentSession else { return }
        guard let playerIndex = session.players.firstIndex(where: { $0.id == playerId }) else { return }

        session.players[playerIndex].isEliminated = true
        let eliminated = session.players[playerIndex]

        if session.currentRoundIndex < session.rounds.count {
            session.rounds[session.currentRoundIndex].eliminatedPlayerId = playerId
            session.rounds[session.currentRoundIndex].outcome = SessionWinChecker.checkWinner(
                players: session.players,
                settings: session.settings
            )
        }

        session.state = .revealing
        currentSession = session

        _ = eliminated
    }

    func continueAfterElimination() {
        guard var session = currentSession else { return }
        guard sessionWinner == nil else { return }

        let round = Round(index: session.rounds.count, wordPairId: currentRound?.wordPairId)
        session.rounds.append(round)
        session.currentRoundIndex = session.rounds.count - 1
        session.state = .discussing
        let activeIds = session.players.filter { !$0.isEliminated }.map(\.id)
        session.discussionStartPlayerId = (try? CryptoRandom.shuffled(activeIds).first) ?? activeIds.first
        currentSession = session
    }

    func resetRoundForPlayAgain() {
        guard var session = currentSession else { return }
        session.state = .lobby
        session.rounds = []
        session.currentRoundIndex = 0
        session.passOrderPlayerIds = []
        session.discussionStartPlayerId = nil
        session.players = session.players.map { player in
            var updated = player
            updated.assignment = nil
            updated.hasOpenedCard = false
            updated.isEliminated = false
            updated.pickedCardIndex = nil
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

    var sessionWinner: RoundOutcome? {
        guard let session = currentSession else { return nil }
        return SessionWinChecker.checkWinner(players: session.players, settings: session.settings)
    }

    var isSessionComplete: Bool {
        sessionWinner != nil
    }

    var activePlayerCount: Int {
        currentSession?.players.filter { !$0.isEliminated }.count ?? 0
    }

    var roundOutcome: RoundOutcome? {
        currentRound?.outcome
    }

    var discussionStarter: PlayerSlot? {
        guard let session = currentSession,
              let id = session.discussionStartPlayerId else { return nil }
        return session.players.first { $0.id == id && !$0.isEliminated }
    }

    private func assignRandomDiscussionStarter() {
        guard var session = currentSession else { return }
        let activeIds = session.players.filter { !$0.isEliminated }.map(\.id)
        guard !activeIds.isEmpty else { return }
        session.discussionStartPlayerId = (try? CryptoRandom.shuffled(activeIds).first) ?? activeIds.first
        currentSession = session
    }

    private func orderedPlayers(from ids: [UUID], in players: [PlayerSlot]) -> [PlayerSlot] {
        let lookup = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        let ordered = ids.compactMap { lookup[$0] }
        let remaining = players.filter { !ids.contains($0.id) }
        return ordered + remaining
    }

    private func normalizedSeatingOrderIds(for session: GameSession) -> [UUID] {
        resolvePlayerOrder(
            ids: session.seatingOrderPlayerIds.isEmpty
                ? session.players.map(\.id)
                : session.seatingOrderPlayerIds,
            in: session.players
        ).map(\.id)
    }

    private func resolvePlayerOrder(ids: [UUID], in players: [PlayerSlot]) -> [PlayerSlot] {
        orderedPlayers(from: ids, in: players)
    }

    private func randomPassOrder(from seatingIds: [UUID]) throws -> [UUID] {
        guard seatingIds.count > 1 else { return seatingIds }
        let startIndex = try CryptoRandom.randomInt(in: 0..<seatingIds.count)
        return Array(seatingIds[startIndex...] + seatingIds[..<startIndex])
    }
}
