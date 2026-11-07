import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private let dependencies: AppDependencies

    var wordPairStats: WordPairStats?
    var showGameRules = false
    var showGameSettings = false
    var showCustomPacks = false
    var showClearDataConfirmation = false
    var showDeleteAccountConfirmation = false
    var accountEmail = ""
    var accountPassword = ""
    var accountMessage: String?
    var isAccountBusy = false
    var isPackAccountSignedIn = false
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
        Task {
            await dependencies.customWordPackService.sync()
            loadWordPairStats()
        }
    }

    func openGameRules() {
        showGameRules = true
    }

    func openGameSettings() {
        isPackAccountSignedIn = dependencies.customWordPackService.isSignedIn
        accountMessage = nil
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

    var canSignInToPackAccount: Bool {
        dependencies.customWordPackService.isConfigured
            && accountEmail.contains("@")
            && !accountPassword.isEmpty
    }

    var canCreatePackAccount: Bool {
        dependencies.customWordPackService.isConfigured
            && accountEmail.contains("@")
            && SupabasePasswordRule.accepts(accountPassword)
    }

    var passwordRequirement: String {
        guard !accountPassword.isEmpty, let message = SupabasePasswordRule.rejectionMessage(for: accountPassword) else {
            return "At least 6 characters."
        }
        return message
    }

    func signInToPackAccount() {
        submitPackAccount { await self.dependencies.customWordPackService.signIn(email: self.normalizedAccountEmail, password: self.accountPassword) }
    }

    func createPackAccount() {
        submitPackAccount { await self.dependencies.customWordPackService.createAccount(email: self.normalizedAccountEmail, password: self.accountPassword) }
    }

    var canSendPasswordReset: Bool {
        dependencies.customWordPackService.isConfigured && accountEmail.contains("@")
    }

    func sendPasswordReset() {
        guard !isAccountBusy, canSendPasswordReset else { return }
        isAccountBusy = true
        accountMessage = nil
        Task {
            accountMessage = await dependencies.customWordPackService.requestPasswordReset(email: normalizedAccountEmail)
            isAccountBusy = false
        }
    }

    func signOutOfPackAccount() {
        dependencies.customWordPackService.signOut()
        isPackAccountSignedIn = false
        accountPassword = ""
        accountMessage = nil
    }

    // Confirmed from Game Settings. https://github.com/kotinarupali/mismatch-ios/issues/45
    func deletePackAccount() {
        guard !isAccountBusy else { return }
        isAccountBusy = true
        accountMessage = nil
        Task {
            let message = await dependencies.customWordPackService.deleteAccount()
            isAccountBusy = false
            isPackAccountSignedIn = dependencies.customWordPackService.isSignedIn
            accountMessage = message ?? "Account deleted."
            showDeleteAccountConfirmation = false
        }
    }

    private var normalizedAccountEmail: String {
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func submitPackAccount(_ action: @escaping () async -> String?) {
        guard canSignInToPackAccount || canCreatePackAccount else { return }
        isAccountBusy = true
        accountMessage = nil
        Task {
            accountMessage = await action()
            isAccountBusy = false
            isPackAccountSignedIn = dependencies.customWordPackService.isSignedIn
            if isPackAccountSignedIn {
                accountPassword = ""
            }
        }
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

    func openCustomPacks() {
        showCustomPacks = true
    }

    func makeCustomPacksViewModel() -> CustomPacksViewModel {
        CustomPacksViewModel(service: dependencies.customWordPackService) { [weak self] in
            self?.showCustomPacks = false
        }
    }

    func clearDataAndResetWords() {
        dependencies.wordPairUsageStore.resetAll()
        try? dependencies.profileRepository.deleteAll()
        dependencies.gameSessionStore.reset()
        dependencies.profilesViewModel.reload()
        loadWordPairStats()
        showClearDataConfirmation = false
    }

    private func persistPreferences() {
        preferences = preferences.normalized()
        dependencies.hostPreferencesStore.save(preferences)
    }

    func refreshWordPairStats() {
        loadWordPairStats()
    }

    private func loadWordPairStats() {
        let builtInIds = (try? dependencies.wordPackLoader.loadCatalog())?.packs.map(\.id) ?? []
        let builtIn = (try? dependencies.wordPairSelector.aggregateStats(for: builtInIds))
            ?? WordPairStats(used: 0, remaining: 0, total: 0)
        let custom = dependencies.customWordPackService.packs
        guard !builtInIds.isEmpty || !custom.isEmpty else {
            wordPairStats = nil
            return
        }
        let customUsed = custom.reduce(0) { $0 + $1.stats.used }
        let customRemaining = custom.reduce(0) { $0 + $1.stats.remaining }
        let customTotal = custom.reduce(0) { $0 + $1.stats.total }
        wordPairStats = WordPairStats(
            used: builtIn.used + customUsed,
            remaining: builtIn.remaining + customRemaining,
            total: builtIn.total + customTotal
        )
    }
}
