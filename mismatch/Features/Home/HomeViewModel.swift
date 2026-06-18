import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private let dependencies: AppDependencies

    var wordPairStats: WordPairStats?
    var showGameRules = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func onAppear() {
        loadWordPairStats()
        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasSeenInlineRules) {
            showGameRules = true
        }
    }

    func openGameRules() {
        showGameRules = true
    }

    func dismissGameRules() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenInlineRules)
        showGameRules = false
    }

    func hostGameTapped() {
        dependencies.gameSessionStore.reset()
        dependencies.gameSessionStore.createSession()
        dependencies.router.navigate(to: .lobby)
    }

    private func loadWordPairStats() {
        wordPairStats = try? dependencies.wordPairSelector.stats()
    }
}
