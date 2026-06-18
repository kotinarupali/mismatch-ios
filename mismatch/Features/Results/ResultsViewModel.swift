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
        if shouldPromptGhostGuess {
            return "One last chance to steal the win."
        }
        if isSessionComplete {
            return "Final results"
        }
        return "\(dependencies.gameSessionStore.activePlayerCount) players still in the game"
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
        finalPlayerReveals
            .filter { winningRoles.contains($0.role) }
            .map(\.displayName)
    }

    var sessionOutcome: RoundOutcome? {
        dependencies.gameSessionStore.sessionWinner
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
        dependencies.repickRoles()
    }

    func exitTapped() {
        dependencies.endGame()
    }
}
