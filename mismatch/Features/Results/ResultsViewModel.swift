import Foundation

@MainActor
@Observable
final class ResultsViewModel {
    private let dependencies: AppDependencies

    var ghostGuess = ""
    var ghostGuessFeedback: String?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var isSessionComplete: Bool {
        dependencies.gameSessionStore.isSessionComplete
    }

    var shouldPromptGhostGuess: Bool {
        dependencies.gameSessionStore.isGhostGuessPending
    }

    var sessionWinnerText: String? {
        guard let winner = dependencies.gameSessionStore.sessionWinner else { return nil }
        let alliance = dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
        return winner.displayText(allianceEnabled: alliance)
    }

    var roundSummary: String {
        let eliminations = roundsPlayed

        if shouldPromptGhostGuess {
            if eliminations > 0 {
                return "\(GameProgressCopy.eliminationLabel(eliminations)) · ghost's last guess"
            }
            return "One last chance to steal the win."
        }
        if isSessionComplete {
            if eliminations > 0 {
                return GameProgressCopy.eliminationLabel(eliminations)
            }
            return "Final results"
        }
        if eliminations > 0 {
            return "\(GameProgressCopy.eliminationLabel(eliminations)) · \(activePlayerCount) players left"
        }
        return "\(activePlayerCount) players still in the game"
    }

    var shouldShowRoundScoreboard: Bool {
        false
    }

    var roundsPlayed: Int {
        dependencies.gameSessionStore.roundsPlayed
    }

    var activePlayerCount: Int {
        dependencies.gameSessionStore.activePlayerCount
    }

    var eliminatedName: String {
        guard let player = dependencies.gameSessionStore.eliminatedPlayer else {
            return "Unknown"
        }
        return player.isHost ? "You" : player.displayName
    }

    var eliminatedRole: String {
        dependencies.gameSessionStore.eliminatedPlayer?.assignment?.role.displayName ?? "Unknown"
    }

    var eliminatedWord: String {
        guard let player = dependencies.gameSessionStore.eliminatedPlayer else {
            return "Unknown"
        }
        if player.assignment?.role == .ghost {
            return dependencies.gameSessionStore.insiderWord ?? "Unknown"
        }
        return player.assignment?.word ?? "None"
    }

    var shouldShowEliminatedWord: Bool {
        !shouldShowFinalResults && isSessionComplete && !shouldPromptGhostGuess
    }

    var shouldShowFinalResults: Bool {
        isSessionComplete && !shouldPromptGhostGuess
    }

    var finalInsiderWord: String {
        dependencies.gameSessionStore.insiderWord ?? "Unknown"
    }

    var finalMismatchWord: String {
        dependencies.gameSessionStore.mismatchWord ?? "Unknown"
    }

    var finalPlayerReveals: [PlayerRoleReveal] {
        dependencies.gameSessionStore.finalPlayerReveals()
    }

    var canSubmitGhostGuess: Bool {
        !ghostGuess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var winningRoles: Set<Role> {
        guard let outcome = sessionOutcome else { return [] }
        let alliance = dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
        return outcome.winningRoles(allianceEnabled: alliance)
    }

    var winningRolesOrdered: [Role] {
        Role.allCases.filter { winningRoles.contains($0) }
    }

    var winnerHeadline: String? {
        guard let outcome = sessionOutcome else { return nil }
        let alliance = dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
        return outcome.celebrationHeadline(allianceEnabled: alliance)
    }

    var winnerPlayerNames: [String] {
        let winnerIds = dependencies.gameSessionStore.sessionWinnerPlayerIds()
        return finalPlayerReveals
            .filter { winnerIds.contains($0.id) }
            .map(\.displayName)
    }

    var sessionOutcome: RoundOutcome? {
        dependencies.gameSessionStore.sessionWinner
    }

    var currentRoundScoreEvents: [ScoreEvent] {
        dependencies.gameSessionStore.currentRoundScoreEvents
    }

    var scoringPlayers: [PlayerSlot] {
        dependencies.gameSessionStore.currentSession?.players ?? []
    }

    var sessionScoreboard: [SessionScoreRow] {
        dependencies.gameSessionStore.sessionScoreboard()
    }

    var hasRoundScores: Bool {
        !currentRoundScoreEvents.isEmpty && !shouldPromptGhostGuess
    }

    var hasSessionScores: Bool {
        sessionScoreboard.contains { $0.sessionScore > 0 }
    }

    var sessionEndScoreEvents: [ScoreEvent] {
        dependencies.gameSessionStore.sessionEndScoreEvents
    }

    var hasWinBonuses: Bool {
        !sessionEndScoreEvents.isEmpty
    }

    var finalScoreboardRows: [FinalScoreboardRow] {
        let revealLookup = Dictionary(uniqueKeysWithValues: finalPlayerReveals.map { ($0.id, $0) })
        let gains = finalScoringGains
        let winnerIds = dependencies.gameSessionStore.sessionWinnerPlayerIds()

        return sessionScoreboard.map { row in
            let reveal = revealLookup[row.id]
            let role = reveal?.role ?? .insider
            return FinalScoreboardRow(
                id: row.id,
                displayName: row.displayName,
                avatarColor: row.avatarColor,
                role: role,
                sessionScore: row.sessionScore,
                pointsGained: gains[row.id] ?? 0,
                rank: row.rank,
                isWinner: winnerIds.contains(row.id),
                isEliminated: reveal?.isEliminated ?? false
            )
        }
    }

    var shouldShowFinalScoreboard: Bool {
        shouldShowFinalResults && !finalScoreboardRows.isEmpty
    }

    private var finalScoringGains: [UUID: Int] {
        ScoringEngine.pointsByPlayer(from: dependencies.gameSessionStore.allScoreEvents())
    }

    var scoreLeaderName: String? {
        sessionScoreboard.first?.displayName
    }

    var gameSessionStore: GameSessionStore {
        dependencies.gameSessionStore
    }

    var insidersWon: Bool {
        sessionOutcome == .insiderSideWins
    }

    func submitGhostGuessTapped() {
        guard canSubmitGhostGuess else { return }
        let isCorrect = dependencies.gameSessionStore.submitGhostGuess(ghostGuess)
        ghostGuess = ""
        if isCorrect {
            ghostGuessFeedback = nil
        } else {
            ghostGuessFeedback = "Wrong guess."
        }
    }

    func continueTapped() {
        dependencies.gameSessionStore.continueAfterElimination()
        dependencies.router.continueToDiscussion()
    }

    func playAgainTapped() {
        Task { await dependencies.playAgainSameGroup() }
    }

    func repickRolesTapped() {
        dependencies.repickRoles()
    }

    func exitTapped() {
        dependencies.showSessionSummary()
    }

    func endSessionTapped() {
        dependencies.showSessionSummary()
    }
}
