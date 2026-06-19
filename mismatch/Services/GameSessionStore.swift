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
        session.currentInsiderWord = wordPair.insiderWord
        session.currentMismatchWord = wordPair.mismatchWord
        session.forcedSessionOutcome = nil
        session.sessionEndScoreEvents = []
        session.sessionWinBonusesApplied = false
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

    func canSwapGhostRole(from playerId: UUID) -> Bool {
        guard let session = currentSession,
              session.settings.ghostPickAgainEnabled,
              session.settings.ghostEnabled,
              session.players.first(where: { $0.id == playerId })?.assignment?.role == .ghost else {
            return false
        }

        let unpickedOthers = session.players.filter {
            $0.id != playerId && !$0.hasOpenedCard && $0.assignment?.role != .ghost
        }
        // Need at least two players still waiting to pick so Ghost can pass the role on.
        return unpickedOthers.count >= 2
    }

    /// Moves the ghost role onto a random player who has not opened a card yet.
    /// Returns the new assignment for the player who gave up ghost.
    func swapGhostRoleAway(from playerId: UUID) -> RoleAssignment? {
        guard var session = currentSession else { return nil }
        guard let ghostIndex = session.players.firstIndex(where: { $0.id == playerId }) else { return nil }

        if session.players[ghostIndex].assignment?.role != .ghost {
            return session.players[ghostIndex].assignment
        }

        guard canSwapGhostRole(from: playerId) else { return nil }

        let partnerIds = session.players.compactMap { player -> UUID? in
            guard player.id != playerId,
                  !player.hasOpenedCard,
                  player.assignment?.role != .ghost else { return nil }
            return player.id
        }
        guard let partnerId = try? CryptoRandom.shuffled(partnerIds).first,
              let partnerIndex = session.players.firstIndex(where: { $0.id == partnerId }),
              let ghostAssignment = session.players[ghostIndex].assignment,
              let partnerAssignment = session.players[partnerIndex].assignment else {
            return nil
        }

        session.players[ghostIndex].assignment = partnerAssignment
        session.players[partnerIndex].assignment = ghostAssignment
        currentSession = session
        return partnerAssignment
    }

    func releaseCardPick(for playerId: UUID) {
        guard var session = currentSession else { return }
        guard let index = session.players.firstIndex(where: { $0.id == playerId }) else { return }
        session.players[index].hasOpenedCard = false
        session.players[index].pickedCardIndex = nil
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
            let name = player.displayName
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

    func setSharedJoinURL(
        _ url: String,
        sessionToken: String,
        hostKey: String? = nil,
        backend: CardDeliveryBackend = .local
    ) {
        guard var session = currentSession else { return }
        session.sharedJoinURL = url
        session.joinSessionToken = sessionToken
        session.cloudHostKey = hostKey
        session.cardDeliveryBackend = backend
        currentSession = session
    }

    func applyRemoteCardSnapshot(_ snapshot: RemoteCardSessionSnapshot) {
        guard var session = currentSession else { return }

        for claim in snapshot.claimedCards {
            guard let index = session.players.firstIndex(where: { $0.id == claim.playerId }) else { continue }
            session.players[index].hasOpenedCard = true
            session.players[index].pickedCardIndex = claim.cardIndex
        }

        if let assignments = snapshot.assignments {
            let hostId = session.players.first(where: \.isHost)?.id
            for assignment in assignments {
                guard let index = session.players.firstIndex(where: { $0.id == assignment.id }) else { continue }
                let incoming = RoleAssignment(
                    role: assignment.role,
                    word: assignment.word,
                    categoryHint: assignment.categoryHint
                )
                let current = session.players[index].assignment
                if current == incoming { continue }
                // Host may swap locally before the cloud POST completes; ignore stale ghost payloads.
                if assignment.id == hostId,
                   !session.players[index].hasOpenedCard,
                   current?.role != .ghost,
                   incoming.role == .ghost {
                    continue
                }
                session.players[index].assignment = incoming
            }
        }

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
            if eliminated.assignment?.role == .ghost {
                if session.currentInsiderWord == nil {
                    session.currentInsiderWord = Self.resolveInsiderWord(in: session)
                }
                session.rounds[session.currentRoundIndex].ghostGuessPending = true
                session.rounds[session.currentRoundIndex].ghostGuessSubmitted = false
                session.rounds[session.currentRoundIndex].outcome = nil
            } else {
                session.rounds[session.currentRoundIndex].outcome = SessionWinChecker.checkWinner(
                    players: session.players,
                    settings: session.settings
                )
            }
        }

        session.state = .revealing
        currentSession = session

        if eliminated.assignment?.role != .ghost {
            finishScoringForCurrentRound(ghostGuessCorrect: nil)
        }
    }

    @discardableResult
    func submitGhostGuess(_ guess: String) -> Bool {
        guard var session = currentSession,
              session.currentRoundIndex < session.rounds.count else { return false }

        let roundIndex = session.currentRoundIndex
        guard session.rounds[roundIndex].ghostGuessPending,
              !session.rounds[roundIndex].ghostGuessSubmitted,
              let insiderWord = Self.resolveInsiderWord(in: session) else { return false }

        let isCorrect = WordGuessMatcher.matches(guess, secret: insiderWord)
        session.rounds[roundIndex].ghostGuessSubmitted = true
        session.rounds[roundIndex].ghostGuessPending = false

        if isCorrect {
            let allianceWin: RoundOutcome = session.settings.mismatchGhostAlliance ? .outsiderSideWins : .ghostWins
            session.forcedSessionOutcome = allianceWin
            session.rounds[roundIndex].outcome = allianceWin
        } else {
            session.rounds[roundIndex].outcome = SessionWinChecker.checkWinner(
                players: session.players,
                settings: session.settings
            )
        }

        currentSession = session
        finishScoringForCurrentRound(ghostGuessCorrect: isCorrect)
        return isCorrect
    }

    var isGhostGuessPending: Bool {
        guard let round = currentRound else { return false }
        return round.ghostGuessPending && !round.ghostGuessSubmitted
    }

    var insiderWord: String? {
        guard let session = currentSession else { return nil }
        return Self.resolveInsiderWord(in: session)
    }

    var mismatchWord: String? {
        guard let session = currentSession else { return nil }
        return Self.resolveMismatchWord(in: session)
    }

    func finalPlayerReveals() -> [PlayerRoleReveal] {
        guard let session = currentSession else { return [] }
        return seatingOrderPlayers().compactMap { player in
            guard let role = player.assignment?.role else { return nil }
            return PlayerRoleReveal(
                id: player.id,
                displayName: player.displayName,
                avatarColor: player.avatarColor,
                role: role,
                isEliminated: player.isEliminated
            )
        }
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

    @discardableResult
    func endGameOnNoConsensus() -> RoundOutcome? {
        guard var session = currentSession else { return nil }
        guard !isGhostGuessPending else { return nil }
        guard let outcome = SessionWinChecker.checkNoConsensusWinner(
            players: session.players,
            settings: session.settings
        ) else { return nil }

        session.forcedSessionOutcome = outcome
        let roundIndex = session.currentRoundIndex
        if roundIndex < session.rounds.count, session.rounds[roundIndex].outcome == nil {
            session.rounds[roundIndex].outcome = outcome
        }
        currentSession = session
        applySessionWinBonusesIfNeeded()
        return outcome
    }

    var hasRoleAssignments: Bool {
        currentSession?.players.contains { $0.assignment != nil } ?? false
    }

    /// Clears card picks and round progress while keeping the current role deal intact.
    func repickCardClaims() throws {
        guard var session = currentSession else {
            throw GameSessionStoreError.noActiveSession
        }
        guard session.players.contains(where: { $0.assignment != nil }) else {
            throw GameSessionStoreError.noActiveSession
        }

        reverseScoreEvents(
            session.rounds.flatMap(\.scoreEvents) + session.sessionEndScoreEvents,
            in: &session
        )

        if session.sessionWinBonusesApplied {
            session.gamesPlayedCount = max(0, session.gamesPlayedCount - 1)
        }

        let wordPairId = session.rounds.first?.wordPairId
        session.players = session.players.map { player in
            var updated = player
            updated.hasOpenedCard = false
            updated.pickedCardIndex = nil
            updated.isEliminated = false
            updated.cardToken = nil
            updated.cardURL = nil
            return updated
        }

        session.rounds = [Round(index: 0, wordPairId: wordPairId)]
        session.currentRoundIndex = 0
        session.passOrderPlayerIds = try randomPassOrder(from: normalizedSeatingOrderIds(for: session))
        session.discussionStartPlayerId = nil
        session.forcedSessionOutcome = nil
        session.sessionEndScoreEvents = []
        session.sessionWinBonusesApplied = false
        session.sharedJoinURL = nil
        session.joinSessionToken = nil
        session.cloudHostKey = nil
        session.cardDeliveryBackend = .local
        session.state = .distributing
        currentSession = session
    }

    func resetRoundForPlayAgain() {
        guard var session = currentSession else { return }

        let completedEvents = session.rounds.flatMap(\.scoreEvents) + session.sessionEndScoreEvents
        if !completedEvents.isEmpty {
            session.lastCompletedGamePointsByPlayer = ScoringEngine.pointsByPlayer(from: completedEvents)
        }

        session.state = .lobby
        session.rounds = []
        session.currentRoundIndex = 0
        session.passOrderPlayerIds = []
        session.discussionStartPlayerId = nil
        session.currentInsiderWord = nil
        session.currentMismatchWord = nil
        session.forcedSessionOutcome = nil
        session.sharedJoinURL = nil
        session.joinSessionToken = nil
        session.cloudHostKey = nil
        session.cardDeliveryBackend = .local
        session.sessionEndScoreEvents = []
        session.sessionWinBonusesApplied = false
        session.summaryScoreByPlayer = [:]
        session.summaryLastGamePointsByPlayer = [:]
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

    func playerPersonaCards() -> [PlayerPersonaCard] {
        guard let session = currentSession else { return [] }
        return PersonaEngine.buildCards(from: session)
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
        if isGhostGuessPending {
            return nil
        }
        if let forced = session.forcedSessionOutcome {
            return forced
        }
        return SessionWinChecker.checkWinner(players: session.players, settings: session.settings)
    }

    /// Players who actually won the session — surviving members of the winning faction,
    /// plus an eliminated Ghost only if they stole the win with a correct guess.
    func sessionWinnerPlayerIds() -> Set<UUID> {
        guard let session = currentSession,
              let outcome = sessionWinner else { return [] }

        let winningRoles = outcome.winningRoles(allianceEnabled: session.settings.mismatchGhostAlliance)
        var winners = Set<UUID>()

        for player in session.players {
            guard let role = player.assignment?.role, winningRoles.contains(role) else { continue }
            if !player.isEliminated {
                winners.insert(player.id)
            } else if role == .ghost, playerHasGhostCorrectGuess(playerId: player.id) {
                winners.insert(player.id)
            }
        }

        return winners
    }

    func playerHasGhostCorrectGuess(playerId: UUID) -> Bool {
        guard let session = currentSession else { return false }
        return session.rounds.contains { round in
            round.scoreEvents.contains { $0.playerId == playerId && $0.reason == .ghostCorrectGuess }
        }
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

    var currentRoundScoreEvents: [ScoreEvent] {
        currentRound?.scoreEvents ?? []
    }

    var roundsPlayed: Int {
        currentSession?.rounds.filter { $0.eliminatedPlayerId != nil }.count ?? 0
    }

    var gamesPlayedCount: Int {
        currentSession?.gamesPlayedCount ?? 0
    }

    var eliminationRoundsInCurrentGame: Int {
        roundsPlayed
    }

    var sessionEndScoreEvents: [ScoreEvent] {
        currentSession?.sessionEndScoreEvents ?? []
    }

    func allScoreEvents() -> [ScoreEvent] {
        guard let session = currentSession else { return [] }
        return session.rounds.flatMap(\.scoreEvents) + session.sessionEndScoreEvents
    }

    /// Score events for the active game only — round eliminations plus end-of-game bonuses.
    func currentGameScoreEvents() -> [ScoreEvent] {
        allScoreEvents()
    }

    func sessionScoreboard(
        roundPoints: [UUID: Int]? = nil,
        showsRoundPoints: Bool = true,
        scoreOverride: [UUID: Int]? = nil
    ) -> [SessionScoreRow] {
        guard let session = currentSession else { return [] }
        let roundLookup = roundPoints ?? ScoringEngine.pointsByPlayer(from: currentRoundScoreEvents)
        let rows = session.players.map { player in
            SessionScoreRow(
                id: player.id,
                displayName: player.displayName,
                avatarColor: player.avatarColor,
                sessionScore: scoreOverride?[player.id] ?? player.sessionScore,
                roundPoints: showsRoundPoints ? (roundLookup[player.id] ?? 0) : 0,
                isHost: player.isHost,
                rank: 0
            )
        }
        .sorted { lhs, rhs in
            if lhs.sessionScore != rhs.sessionScore {
                return lhs.sessionScore > rhs.sessionScore
            }
            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }

        // Shared rank (competition ranking): tied scores share rank; next rank skips (1, 1, 3).
        return SessionScoreboardRanker.assignSharedRanks(to: rows)
    }

    func sessionSummaryScoreboard() -> [SessionScoreRow] {
        guard let session = currentSession else { return [] }

        let totals = !session.summaryScoreByPlayer.isEmpty
            ? session.summaryScoreByPlayer
            : Dictionary(uniqueKeysWithValues: session.players.map { ($0.id, $0.sessionScore) })

        let lastGamePoints: [UUID: Int]
        if !session.summaryLastGamePointsByPlayer.isEmpty {
            lastGamePoints = session.summaryLastGamePointsByPlayer
        } else {
            let currentGamePoints = ScoringEngine.pointsByPlayer(from: allScoreEvents())
            lastGamePoints = currentGamePoints.isEmpty
                ? session.lastCompletedGamePointsByPlayer
                : currentGamePoints
        }

        return sessionScoreboard(
            roundPoints: lastGamePoints,
            showsRoundPoints: true,
            scoreOverride: totals
        )
    }

    func sessionSummaryFinalScoreboardRows() -> [FinalScoreboardRow] {
        let reveals = Dictionary(uniqueKeysWithValues: finalPlayerReveals().map { ($0.id, $0) })
        guard !reveals.isEmpty else { return [] }

        let winnerIds = sessionWinnerPlayerIds()
        return sessionSummaryScoreboard().map { row in
            let reveal = reveals[row.id]
            return FinalScoreboardRow(
                id: row.id,
                displayName: row.displayName,
                avatarColor: row.avatarColor,
                role: reveal?.role ?? .insider,
                sessionScore: row.sessionScore,
                pointsGained: row.roundPoints,
                rank: row.rank,
                isWinner: winnerIds.contains(row.id),
                isEliminated: reveal?.isEliminated ?? false
            )
        }
    }

    func markSessionEnded() {
        guard var session = currentSession else { return }
        captureSummaryScoreSnapshot(&session)
        session.state = .ended
        currentSession = session
    }

    private func captureSummaryScoreSnapshot(_ session: inout GameSession) {
        let currentGamePoints = ScoringEngine.pointsByPlayer(
            from: session.rounds.flatMap(\.scoreEvents) + session.sessionEndScoreEvents
        )

        session.summaryScoreByPlayer = Dictionary(
            uniqueKeysWithValues: session.players.map { ($0.id, $0.sessionScore) }
        )

        if !currentGamePoints.isEmpty {
            session.summaryLastGamePointsByPlayer = currentGamePoints
        } else {
            session.summaryLastGamePointsByPlayer = session.lastCompletedGamePointsByPlayer
        }
    }

    var hasPendingProfileStatsSync: Bool {
        guard let session = currentSession else { return false }
        return session.profileStatsSyncedGamesCount < session.gamesPlayedCount
            && session.sessionWinBonusesApplied
            && session.players.contains { $0.assignment != nil }
    }

    func markProfileStatsSyncedForCompletedGame() {
        guard var session = currentSession else { return }
        session.profileStatsSyncedGamesCount += 1
        currentSession = session
    }

    private func finishScoringForCurrentRound(ghostGuessCorrect: Bool?) {
        applyRoundScores(ghostGuessCorrect: ghostGuessCorrect)
        applySessionWinBonusesIfNeeded()
    }

    private func reverseScoreEvents(_ events: [ScoreEvent], in session: inout GameSession) {
        for event in events {
            guard let index = session.players.firstIndex(where: { $0.id == event.playerId }) else { continue }
            session.players[index].sessionScore -= event.points
        }
    }

    private func applyRoundScores(ghostGuessCorrect: Bool?) {
        guard var session = currentSession else { return }
        let roundIndex = session.currentRoundIndex
        guard roundIndex < session.rounds.count else { return }
        guard session.rounds[roundIndex].scoreEvents.isEmpty else { return }
        guard let eliminatedPlayerId = session.rounds[roundIndex].eliminatedPlayerId else { return }

        let events = ScoringEngine.computeRoundScores(
            players: session.players,
            eliminatedPlayerId: eliminatedPlayerId,
            ghostGuessCorrect: ghostGuessCorrect
        )
        guard !events.isEmpty else { return }

        session.rounds[roundIndex].scoreEvents = events
        for event in events {
            guard let index = session.players.firstIndex(where: { $0.id == event.playerId }) else { continue }
            session.players[index].sessionScore += event.points
        }
        currentSession = session
    }

    private func applySessionWinBonusesIfNeeded() {
        guard var session = currentSession else { return }
        guard !session.sessionWinBonusesApplied else { return }
        guard !isGhostGuessPending else { return }
        guard let outcome = sessionWinner else { return }

        let events = ScoringEngine.computeSessionWinBonuses(
            players: session.players,
            outcome: outcome,
            settings: session.settings
        )

        session.sessionEndScoreEvents = events
        session.sessionWinBonusesApplied = true
        session.gamesPlayedCount += 1
        for event in events {
            guard let index = session.players.firstIndex(where: { $0.id == event.playerId }) else { continue }
            session.players[index].sessionScore += event.points
        }
        currentSession = session
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

    private static func resolveInsiderWord(in session: GameSession) -> String? {
        if let stored = session.currentInsiderWord?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stored.isEmpty {
            return stored
        }

        if let word = session.players
            .compactMap(\.assignment)
            .first(where: { $0.role == .insider })?
            .word?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !word.isEmpty {
            return word
        }

        return nil
    }

    private static func resolveMismatchWord(in session: GameSession) -> String? {
        if let stored = session.currentMismatchWord?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stored.isEmpty {
            return stored
        }

        if let word = session.players
            .compactMap(\.assignment)
            .first(where: { $0.role == .mismatch })?
            .word?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !word.isEmpty {
            return word
        }

        return nil
    }
}
