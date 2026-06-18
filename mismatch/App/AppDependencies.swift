import SwiftUI

@MainActor
final class AppDependencies {
    let gameSessionStore: GameSessionStore
    let wordPackLoader: WordPackLoader
    let wordPairUsageStore: WordPairUsageStore
    let wordPairSelector: WordPairSelector
    let router: AppRouter
    let timerService: TimerService
    let localCardSessionStore: LocalCardSessionStore
    let localNetworkCardServer: LocalNetworkCardServer
    private(set) lazy var lobbyViewModel = LobbyViewModel(dependencies: self)

    init() {
        gameSessionStore = GameSessionStore()
        wordPackLoader = WordPackLoader()
        wordPairUsageStore = WordPairUsageStore()
        wordPairSelector = WordPairSelector(loader: wordPackLoader, usageStore: wordPairUsageStore)
        router = AppRouter()
        timerService = TimerService()
        localCardSessionStore = LocalCardSessionStore()
        localNetworkCardServer = LocalNetworkCardServer(sessionStore: localCardSessionStore)
    }

    init(
        gameSessionStore: GameSessionStore,
        wordPackLoader: WordPackLoader,
        wordPairUsageStore: WordPairUsageStore,
        wordPairSelector: WordPairSelector,
        router: AppRouter,
        timerService: TimerService,
        localCardSessionStore: LocalCardSessionStore,
        localNetworkCardServer: LocalNetworkCardServer
    ) {
        self.gameSessionStore = gameSessionStore
        self.wordPackLoader = wordPackLoader
        self.wordPairUsageStore = wordPairUsageStore
        self.wordPairSelector = wordPairSelector
        self.router = router
        self.timerService = timerService
        self.localCardSessionStore = localCardSessionStore
        self.localNetworkCardServer = localNetworkCardServer
    }

    func repickRoles() {
        timerService.stop()
        localNetworkCardServer.stop()
        gameSessionStore.resetRoundForPlayAgain()
        lobbyViewModel.reloadFromSession()
        router.replaceWithLobby()
    }

    func prepareLobby() {
        lobbyViewModel.reloadFromSession()
    }

    func endGame() {
        timerService.stop()
        localNetworkCardServer.stop()
        gameSessionStore.reset()
        router.popToRoot()
    }
}
