import SwiftUI

@MainActor
final class AppDependencies {
    let gameSessionStore: GameSessionStore
    let wordPackLoader: WordPackLoader
    let router: AppRouter
    let timerService: TimerService
    let localCardTokenStore: LocalCardTokenStore
    let localNetworkCardServer: LocalNetworkCardServer

    init() {
        gameSessionStore = GameSessionStore()
        wordPackLoader = WordPackLoader()
        router = AppRouter()
        timerService = TimerService()
        localCardTokenStore = LocalCardTokenStore()
        localNetworkCardServer = LocalNetworkCardServer(tokenStore: localCardTokenStore)
    }

    init(
        gameSessionStore: GameSessionStore,
        wordPackLoader: WordPackLoader,
        router: AppRouter,
        timerService: TimerService,
        localCardTokenStore: LocalCardTokenStore,
        localNetworkCardServer: LocalNetworkCardServer
    ) {
        self.gameSessionStore = gameSessionStore
        self.wordPackLoader = wordPackLoader
        self.router = router
        self.timerService = timerService
        self.localCardTokenStore = localCardTokenStore
        self.localNetworkCardServer = localNetworkCardServer
    }
}
