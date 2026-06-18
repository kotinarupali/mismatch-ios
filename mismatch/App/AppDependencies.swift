import SwiftUI

@MainActor
final class AppDependencies {
    let gameSessionStore: GameSessionStore
    let wordPackLoader: WordPackLoader
    let wordPairUsageStore: WordPairUsageStore
    let wordPairSelector: WordPairSelector
    let router: AppRouter
    let timerService: TimerService
    let localCardTokenStore: LocalCardTokenStore
    let localNetworkCardServer: LocalNetworkCardServer

    init() {
        gameSessionStore = GameSessionStore()
        wordPackLoader = WordPackLoader()
        wordPairUsageStore = WordPairUsageStore()
        wordPairSelector = WordPairSelector(loader: wordPackLoader, usageStore: wordPairUsageStore)
        router = AppRouter()
        timerService = TimerService()
        localCardTokenStore = LocalCardTokenStore()
        localNetworkCardServer = LocalNetworkCardServer(tokenStore: localCardTokenStore)
    }

    init(
        gameSessionStore: GameSessionStore,
        wordPackLoader: WordPackLoader,
        wordPairUsageStore: WordPairUsageStore,
        wordPairSelector: WordPairSelector,
        router: AppRouter,
        timerService: TimerService,
        localCardTokenStore: LocalCardTokenStore,
        localNetworkCardServer: LocalNetworkCardServer
    ) {
        self.gameSessionStore = gameSessionStore
        self.wordPackLoader = wordPackLoader
        self.wordPairUsageStore = wordPairUsageStore
        self.wordPairSelector = wordPairSelector
        self.router = router
        self.timerService = timerService
        self.localCardTokenStore = localCardTokenStore
        self.localNetworkCardServer = localNetworkCardServer
    }

    func repickRoles() {
        timerService.stop()
        localNetworkCardServer.stop()
        gameSessionStore.resetRoundForPlayAgain()
        router.replaceWithLobby()
    }

    func endGame() {
        timerService.stop()
        localNetworkCardServer.stop()
        gameSessionStore.reset()
        router.popToRoot()
    }
}
