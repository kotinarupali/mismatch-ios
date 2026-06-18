import SwiftUI
import SwiftData

@MainActor
final class AppDependencies {
    let modelContainer: ModelContainer
    let profileRepository: ProfileRepository
    let gameSessionStore: GameSessionStore
    let wordPackLoader: WordPackLoader
    let wordPairUsageStore: WordPairUsageStore
    let wordPairSelector: WordPairSelector
    let router: AppRouter
    let timerService: TimerService
    let localCardSessionStore: LocalCardSessionStore
    let localNetworkCardServer: LocalNetworkCardServer
    let remoteCardSessionClient: RemoteCardSessionClient
    let hostPreferencesStore: HostPreferencesStore
    private(set) lazy var lobbyViewModel = LobbyViewModel(dependencies: self)
    private(set) lazy var profilesViewModel = ProfilesViewModel(dependencies: self)

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.profileRepository = ProfileRepository(modelContext: modelContainer.mainContext)
        self.gameSessionStore = GameSessionStore()
        self.wordPackLoader = WordPackLoader()
        self.wordPairUsageStore = WordPairUsageStore()
        self.wordPairSelector = WordPairSelector(loader: wordPackLoader, usageStore: wordPairUsageStore)
        self.router = AppRouter()
        self.timerService = TimerService()
        self.localCardSessionStore = LocalCardSessionStore()
        self.localNetworkCardServer = LocalNetworkCardServer(sessionStore: localCardSessionStore)
        self.remoteCardSessionClient = RemoteCardSessionClient()
        self.hostPreferencesStore = HostPreferencesStore()
    }

    convenience init() {
        let container: ModelContainer
        do {
            container = try SwiftDataContainer.makeProduction()
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
        self.init(modelContainer: container)
    }

    static func makeForTesting(inMemorySwiftData: Bool = true) throws -> AppDependencies {
        let container = try inMemorySwiftData
            ? SwiftDataContainer.makeInMemory()
            : SwiftDataContainer.makeProduction()
        return AppDependencies(modelContainer: container)
    }

    init(
        modelContainer: ModelContainer,
        gameSessionStore: GameSessionStore,
        wordPackLoader: WordPackLoader,
        wordPairUsageStore: WordPairUsageStore,
        wordPairSelector: WordPairSelector,
        router: AppRouter,
        timerService: TimerService,
        localCardSessionStore: LocalCardSessionStore,
        localNetworkCardServer: LocalNetworkCardServer,
        remoteCardSessionClient: RemoteCardSessionClient,
        hostPreferencesStore: HostPreferencesStore
    ) {
        self.modelContainer = modelContainer
        self.profileRepository = ProfileRepository(modelContext: modelContainer.mainContext)
        self.gameSessionStore = gameSessionStore
        self.wordPackLoader = wordPackLoader
        self.wordPairUsageStore = wordPairUsageStore
        self.wordPairSelector = wordPairSelector
        self.router = router
        self.timerService = timerService
        self.localCardSessionStore = localCardSessionStore
        self.localNetworkCardServer = localNetworkCardServer
        self.remoteCardSessionClient = remoteCardSessionClient
        self.hostPreferencesStore = hostPreferencesStore
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

    func showSessionSummary() {
        timerService.stop()
        stopCardDelivery()
        gameSessionStore.markSessionEnded()
        router.replaceWithSessionSummary()
    }

    func endSessionWithSummary() {
        showSessionSummary()
    }

    func playAgainFromSessionSummary() {
        Task { await playAgainSameGroup() }
    }

    func playAgainSameGroup() async {
        timerService.stop()
        stopCardDelivery()
        gameSessionStore.resetRoundForPlayAgain()
        lobbyViewModel.reloadFromSession()
        await distributeRolesUsingLobbySettings()
    }

    func newGameNight() {
        endGame()
    }

    private func distributeRolesUsingLobbySettings() async {
        let distributionMode = Self.resolvedDistributionMode(
            gameSessionStore.currentSession?.settings.distributionMode ?? .passThePhone
        )

        do {
            let wordPair = try wordPairSelector.nextPair()
            try gameSessionStore.distributeRoles(wordPair: wordPair)
            wordPairSelector.markUsed(wordPair)

            switch distributionMode {
            case .passThePhone:
                router.replaceWithDistribution(.passThePhone)
            case .cloudQR:
                await startCloudQRDistribution()
            }
        } catch {
            router.popToRoot()
        }
    }

    private func startCloudQRDistribution() async {
        guard let session = gameSessionStore.currentSession else { return }

        do {
            let result = try await remoteCardSessionClient.createSession(from: session)
            gameSessionStore.setSharedJoinURL(
                result.joinURL,
                sessionToken: result.sessionToken,
                hostKey: result.hostKey,
                backend: .cloud
            )
            router.replaceWithDistribution(.qrGrid)
        } catch {
            var settings = gameSessionStore.currentSession?.settings ?? .default
            settings.distributionMode = .passThePhone
            gameSessionStore.updateSettings(settings)
            lobbyViewModel.reloadFromSession()
            router.replaceWithDistribution(.passThePhone)
        }
    }

    private static func resolvedDistributionMode(_ mode: DistributionMode) -> DistributionMode {
        if mode == .cloudQR, !CloudCardConfig.isConfigured {
            return .passThePhone
        }
        return mode
    }

    func endGame() {
        timerService.stop()
        stopCardDelivery()
        gameSessionStore.reset()
        router.popToRoot()
    }
}
