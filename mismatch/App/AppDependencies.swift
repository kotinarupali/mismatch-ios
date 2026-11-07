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
    let customWordPackService: CustomWordPackService
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
        self.customWordPackService = CustomWordPackService(
            identity: HostIdentityStore(),
            store: CustomWordPackStore(),
            client: CustomWordPackClient()
        )
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
        hostPreferencesStore: HostPreferencesStore,
        customWordPackService: CustomWordPackService
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
        self.customWordPackService = customWordPackService
    }

    func stopCardDelivery() {
        localNetworkCardServer.stop()
        guard let session = gameSessionStore.currentSession,
              session.cardDeliveryBackend == .cloud,
              let token = session.joinSessionToken,
              let hostKey = session.cloudHostKey else { return }
        Task {
            await remoteCardSessionClient.invalidate(token: token, hostKey: hostKey)
        }
    }

    func repickRoles() {
        timerService.stop()
        stopCardDelivery()

        if gameSessionStore.hasRoleAssignments {
            do {
                try gameSessionStore.repickCardClaims()
            } catch {
                return
            }
            Task { await navigateToDistribution() }
            return
        }

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
        syncCompletedGameProfileStatsIfNeeded()
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
        syncCompletedGameProfileStatsIfNeeded()
        gameSessionStore.resetRoundForPlayAgain()

        if let message = lobbyViewModel.dealSelectedPack() {
            lobbyViewModel.reloadFromSession()
            lobbyViewModel.errorMessage = message
            router.replaceWithLobby()
            return
        }

        await navigateToDistribution()
    }

    func syncCompletedGameProfileStatsIfNeeded() {
        guard gameSessionStore.hasPendingProfileStatsSync,
              let session = gameSessionStore.currentSession else { return }

        let winners = gameSessionStore.sessionWinnerPlayerIds()
        let points = ScoringEngine.pointsByPlayer(from: gameSessionStore.currentGameScoreEvents())
        let hostName = hostPreferencesStore.load().resolvedHostDisplayName

        do {
            try profileRepository.applyCompletedGameStats(
                players: session.players,
                winnerPlayerIds: winners,
                pointsByPlayer: points,
                hostDisplayName: hostName
            )
            gameSessionStore.markProfileStatsSyncedForCompletedGame()
            profilesViewModel.reload()
        } catch {
            // Profiles are optional — ignore write failures during sync.
        }
    }

    func newGameNight() {
        endGame()
    }

    private func navigateToDistribution() async {
        let distributionMode = Self.resolvedDistributionMode(
            gameSessionStore.currentSession?.settings.distributionMode ?? .passThePhone
        )

        switch distributionMode {
        case .passThePhone:
            router.replaceWithDistribution(.passThePhone)
        case .cloudQR:
            await startCloudQRDistribution()
        }
    }

    private func startCloudQRDistribution() async {
        guard let session = gameSessionStore.currentSession else { return }

        do {
            let hostName = hostPreferencesStore.load().resolvedHostDisplayName
            let result = try await remoteCardSessionClient.createSession(
                from: session,
                hostDisplayName: hostName
            )
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
