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
    let remoteCardSessionClient: RemoteCardSessionClient
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
        remoteCardSessionClient = RemoteCardSessionClient()
    }

    init(
        gameSessionStore: GameSessionStore,
        wordPackLoader: WordPackLoader,
        wordPairUsageStore: WordPairUsageStore,
        wordPairSelector: WordPairSelector,
        router: AppRouter,
        timerService: TimerService,
        localCardSessionStore: LocalCardSessionStore,
        localNetworkCardServer: LocalNetworkCardServer,
        remoteCardSessionClient: RemoteCardSessionClient
    ) {
        self.gameSessionStore = gameSessionStore
        self.wordPackLoader = wordPackLoader
        self.wordPairUsageStore = wordPairUsageStore
        self.wordPairSelector = wordPairSelector
        self.router = router
        self.timerService = timerService
        self.localCardSessionStore = localCardSessionStore
        self.localNetworkCardServer = localNetworkCardServer
        self.remoteCardSessionClient = remoteCardSessionClient
    }

    func stopCardDelivery() {
        localNetworkCardServer.stop()
        guard let session = gameSessionStore.currentSession,
              session.cardDeliveryBackend == .cloud,
              let token = session.joinSessionToken else { return }
        Task {
            await remoteCardSessionClient.invalidate(token: token)
        }
    }

    func repickRoles() {
        timerService.stop()
        stopCardDelivery()
        gameSessionStore.resetRoundForPlayAgain()
        lobbyViewModel.reloadFromSession()
        router.replaceWithLobby()
    }

    func prepareLobby() {
        lobbyViewModel.reloadFromSession()
    }

    func endGame() {
        timerService.stop()
        stopCardDelivery()
        gameSessionStore.reset()
        router.popToRoot()
    }
}
