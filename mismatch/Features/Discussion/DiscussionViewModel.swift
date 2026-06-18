import Foundation

@MainActor
@Observable
final class DiscussionViewModel {
    private let dependencies: AppDependencies
    let timerService: TimerService

    let timerDurationSeconds: Int
    var showRolesReveal = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.timerService = dependencies.timerService
        timerDurationSeconds = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
    }

    var timerEnabled: Bool {
        dependencies.gameSessionStore.currentSession?.settings.discussionTimerEnabled ?? false
    }

    var timerLabel: String {
        timerService.formattedTime
    }

    var playersForReveal: [PlayerSlot] {
        dependencies.gameSessionStore.currentSession?.players
            .filter { !$0.isEliminated && $0.assignment != nil } ?? []
    }

    func onAppear() {
        guard timerEnabled else { return }
        let duration = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
        dependencies.timerService.start(durationSeconds: duration) { [weak self] in
            self?.startVotingTapped()
        }
    }

    func onDisappear() {
        dependencies.timerService.stop()
    }

    func startVotingTapped() {
        dependencies.timerService.stop()
        dependencies.gameSessionStore.updateState(.voting)
        dependencies.router.navigate(to: .voting)
    }

    func revealRolesTapped() {
        showRolesReveal = true
    }

    func repickRoles() {
        dependencies.repickRoles()
    }

    func endGame() {
        dependencies.endGame()
    }
}
