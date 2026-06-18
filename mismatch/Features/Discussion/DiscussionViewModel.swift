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

    var ghostEnabled: Bool {
        dependencies.gameSessionStore.currentSession?.settings.ghostEnabled ?? false
    }

    var allPlayers: [PlayerSlot] {
        dependencies.gameSessionStore.seatingOrderPlayers()
    }

    var displayPlayers: [PlayerSlot] {
        guard let starterId = discussionStarterId,
              let startIndex = allPlayers.firstIndex(where: { $0.id == starterId }) else {
            return allPlayers
        }
        return Array(allPlayers[startIndex...] + allPlayers[..<startIndex])
    }

    var discussionStarterId: UUID? {
        dependencies.gameSessionStore.discussionStarter?.id
    }

    var discussionStarterName: String? {
        guard let player = dependencies.gameSessionStore.discussionStarter else { return nil }
        return player.isHost ? "You" : player.displayName
    }

    var activePlayers: [PlayerSlot] {
        allPlayers.filter { !$0.isEliminated }
    }

    var playersWithPickedCards: [PlayerSlot] {
        dependencies.gameSessionStore.playersWithPickedCards()
    }

    var remainingMismatchCount: Int {
        dependencies.gameSessionStore.remainingOutsiderCounts().mismatch
    }

    var remainingGhostCount: Int {
        dependencies.gameSessionStore.remainingOutsiderCounts().ghost
    }

    var selectedPlayerName: String {
        guard let id = selectedPlayerId,
              let player = allPlayers.first(where: { $0.id == id }) else {
            return "this player"
        }
        return player.isHost ? "You" : player.displayName
    }

    var canConfirmVote: Bool {
        guard let id = selectedPlayerId else { return false }
        return activePlayers.contains { $0.id == id }
    }

    func onAppear() {
        dependencies.gameSessionStore.updateState(.discussing)
        if let id = selectedPlayerId,
           allPlayers.first(where: { $0.id == id })?.isEliminated == true {
            selectedPlayerId = nil
        }
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
        guard allPlayers.first(where: { $0.id == id && !$0.isEliminated }) != nil else { return }
        selectedPlayerId = id
    }

    func confirmVoteTapped() {
        guard let id = selectedPlayerId,
              allPlayers.first(where: { $0.id == id && !$0.isEliminated }) != nil else { return }
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
