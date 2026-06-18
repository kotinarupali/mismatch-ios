import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private let dependencies: AppDependencies

    var wordPackPairCount: Int?
    var showInlineRules = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func onAppear() {
        loadWordPackCount()
        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasSeenInlineRules) {
            showInlineRules = true
        }
    }

    func dismissInlineRules() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenInlineRules)
        showInlineRules = false
    }

    func hostGameTapped() {
        dependencies.gameSessionStore.reset()
        dependencies.gameSessionStore.createSession()
        dependencies.router.navigate(to: .lobby)
    }

    private func loadWordPackCount() {
        wordPackPairCount = try? dependencies.wordPackLoader.loadBuiltIn().pairs.count
    }
}
