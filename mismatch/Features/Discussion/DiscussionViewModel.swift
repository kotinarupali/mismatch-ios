import Foundation

@MainActor
@Observable
final class DiscussionViewModel {
    private let dependencies: AppDependencies
    let timerService: TimerService

    let timerDurationSeconds: Int

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.timerService = dependencies.timerService
        timerDurationSeconds = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
    }

    var timerLabel: String {
        timerService.formattedTime
    }

    func onAppear() {
        let duration = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
        dependencies.timerService.start(durationSeconds: duration) { [weak self] in
            self?.endEarlyTapped()
        }
    }

    func onDisappear() {
        dependencies.timerService.stop()
    }

    func endEarlyTapped() {
        dependencies.timerService.stop()
        dependencies.gameSessionStore.updateState(.voting)
        dependencies.router.navigate(to: .voting)
    }
}
