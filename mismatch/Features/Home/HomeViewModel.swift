import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private let dependencies: AppDependencies

    var wordPairStats: WordPairStats?
    var showGameRules = false
    var showGameSettings = false
    private(set) var preferences: HostPreferences

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.preferences = dependencies.hostPreferencesStore.load()
    }

    func onAppear() {
        preferences = dependencies.hostPreferencesStore.load()
        loadWordPairStats()
        if !UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasSeenInlineRules) {
            showGameRules = true
        }
    }

    func openGameRules() {
        showGameRules = true
    }

    func openGameSettings() {
        showGameSettings = true
    }

    func dismissGameRules() {
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.hasSeenInlineRules)
        showGameRules = false
    }

    func setDiscussionTimerEnabled(_ enabled: Bool) {
        preferences.discussionTimerEnabled = enabled
        persistPreferences()
    }

    func setTimerMinutes(_ minutes: Int) {
        preferences.timerMinutes = minutes
        persistPreferences()
    }

    func setHostDisplayName(_ name: String) {
        preferences.hostDisplayName = name
        persistPreferences()
    }

    func hostGameTapped() {
        persistPreferences()
        let settings = preferences.applying(to: .default)
        dependencies.gameSessionStore.reset()
        dependencies.gameSessionStore.createSession(settings: settings)
        dependencies.prepareLobby()
        dependencies.router.navigate(to: .lobby)
    }

    func openProfiles() {
        dependencies.router.navigate(to: .profiles)
    }

    private func persistPreferences() {
        preferences = preferences.normalized()
        dependencies.hostPreferencesStore.save(preferences)
    }

    private func loadWordPairStats() {
        wordPairStats = try? dependencies.wordPairSelector.stats()
    }
}
