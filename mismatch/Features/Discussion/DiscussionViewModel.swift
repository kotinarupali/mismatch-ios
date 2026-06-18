import Foundation

@MainActor
@Observable
final class DiscussionViewModel {
    private let dependencies: AppDependencies
    let timerService: TimerService

    let timerDurationSeconds: Int
    var selectedPlayerId: UUID?
    var showConfirmDialog = false
    var showPlayerRolePicker = false
    var playerToReveal: PlayerSlot?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.timerService = dependencies.timerService
        timerDurationSeconds = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
    }

    var timerEnabled: Bool {
        dependencies.gameSessionStore.currentSession?.settings.discussionTimerEnabled ?? false
    }

    var activePlayers: [PlayerSlot] {
        dependencies.gameSessionStore.currentSession?.players
            .filter { !$0.isEliminated } ?? []
    }

    var playersWithPickedCards: [PlayerSlot] {
        dependencies.gameSessionStore.playersWithPickedCards()
    }

    var selectedPlayerName: String {
        guard let id = selectedPlayerId,
              let player = activePlayers.first(where: { $0.id == id }) else {
            return "this player"
        }
        return player.isHost ? "You" : player.displayName
    }

    func onAppear() {
        dependencies.gameSessionStore.updateState(.discussing)
        guard timerEnabled else { return }
        let duration = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
        dependencies.timerService.start(durationSeconds: duration) { [weak self] in
            self?.dependencies.timerService.stop()
        }
    }

    func onDisappear() {
        dependencies.timerService.stop()
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
        dependencies.timerService.stop()
        dependencies.gameSessionStore.eliminate(playerId: id)
        dependencies.router.navigate(to: .results)
    }

    func checkPlayerRoleTapped() {
        showPlayerRolePicker = true
    }

    func selectPlayerForRoleCheck(_ player: PlayerSlot) {
        playerToReveal = player
    }

    func repickRoles() {
        dependencies.repickRoles()
    }

    func endGame() {
        dependencies.endGame()
    }
}
