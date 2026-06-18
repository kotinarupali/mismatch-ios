import Foundation

@MainActor
@Observable
final class VotingViewModel {
    private let dependencies: AppDependencies

    var selectedPlayerId: UUID?
    var showConfirmDialog = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var activePlayers: [PlayerSlot] {
        dependencies.gameSessionStore.currentSession?.players
            .filter { !$0.isEliminated } ?? []
    }

    var selectedPlayerName: String {
        guard let id = selectedPlayerId,
              let player = activePlayers.first(where: { $0.id == id }) else {
            return "this player"
        }
        return player.isHost ? "You" : player.displayName
    }

    func selectPlayer(_ id: UUID) {
        selectedPlayerId = id
    }

    func confirmVoteTapped() {
        guard selectedPlayerId != nil else { return }
        showConfirmDialog = true
    }

    func submitElimination() {
        guard let id = selectedPlayerId else { return }
        dependencies.gameSessionStore.eliminate(playerId: id)
        dependencies.router.navigate(to: .results)
    }
}
