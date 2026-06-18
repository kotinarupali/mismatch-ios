import Foundation

@MainActor
@Observable
final class ResultsViewModel {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var outcomeText: String {
        dependencies.gameSessionStore.roundOutcome?.displayText ?? "Round complete"
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

    func playAgainTapped() {
        dependencies.localNetworkCardServer.stop()
        dependencies.gameSessionStore.resetRoundForPlayAgain()
        dependencies.router.replaceWithLobby()
    }

    func newGameTapped() {
        dependencies.localNetworkCardServer.stop()
        dependencies.gameSessionStore.reset()
        dependencies.router.popToRoot()
    }
}
