import Foundation

@MainActor
@Observable
final class ResultsViewModel {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var isSessionComplete: Bool {
        dependencies.gameSessionStore.isSessionComplete
    }

    var sessionWinnerText: String? {
        guard let winner = dependencies.gameSessionStore.sessionWinner else { return nil }
        let alliance = dependencies.gameSessionStore.currentSession?.settings.mismatchGhostAlliance ?? false
        return winner.displayText(allianceEnabled: alliance)
    }

    var roundSummary: String {
        if isSessionComplete, let winner = sessionWinnerText {
            return winner
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
        dependencies.gameSessionStore.eliminatedPlayer?.assignment?.word ?? "None"
    }

    func continueTapped() {
        dependencies.gameSessionStore.continueAfterElimination()
        dependencies.router.continueToDiscussion()
    }

    func playAgainTapped() {
        dependencies.repickRoles()
    }

    func newGameTapped() {
        dependencies.endGame()
    }
}
