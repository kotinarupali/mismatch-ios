import Foundation

@MainActor
@Observable
final class LobbyViewModel {
    private let dependencies: AppDependencies

    var hostIsPlaying: Bool
    var ghostEnabled: Bool
    var showRoleOnCard: Bool
    var distributionMode: DistributionMode
    var playerNames: [String]
    var newPlayerName: String = ""
    var isDistributing = false
    var errorMessage: String?

    private let minimumPlayers = 4

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        let settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        hostIsPlaying = settings.hostIsPlaying
        ghostEnabled = settings.ghostEnabled
        showRoleOnCard = settings.showRoleOnCard
        distributionMode = settings.distributionMode
        playerNames = dependencies.gameSessionStore.currentSession?.players
            .filter { !$0.isHost }
            .map(\.displayName) ?? []
    }

    var canAddPlayer: Bool {
        !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canContinue: Bool {
        playerNames.count >= minimumPlayers && !isDistributing
    }

    var statusMessage: String {
        "\(playerNames.count) players · minimum \(minimumPlayers)"
    }

    func addPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playerNames.append(trimmed)
        newPlayerName = ""
        syncSession()
    }

    func removePlayer(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            playerNames.remove(at: index)
        }
        syncSession()
    }

    func distributeRolesTapped() {
        guard canContinue else { return }
        syncSession()
        isDistributing = true
        errorMessage = nil

        Task {
            await performDistribution()
            isDistributing = false
        }
    }

    private func performDistribution() async {
        do {
            let pack = try dependencies.wordPackLoader.loadBuiltIn()
            guard let wordPair = pack.pairs.randomElement() else {
                errorMessage = "No word pairs available."
                return
            }

            try dependencies.gameSessionStore.distributeRoles(wordPair: wordPair)

            switch distributionMode {
            case .passThePhone:
                dependencies.router.navigate(to: .passThePhone)
            case .localQR:
                await startQRDistribution()
            }
        } catch {
            errorMessage = "Could not distribute roles."
        }
    }

    private func startQRDistribution() async {
        guard let session = dependencies.gameSessionStore.currentSession else { return }

        do {
            let urls = try await dependencies.localNetworkCardServer.start(session: session)
            for (playerId, url) in urls {
                let token = url.split(separator: "/").last.map(String.init) ?? ""
                dependencies.gameSessionStore.updatePlayerCardURL(
                    playerId: playerId,
                    token: token,
                    url: url
                )
            }
            dependencies.router.navigate(to: .qrGrid)
        } catch {
            errorMessage = "QR server unavailable. Switching to pass-the-phone."
            var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
            settings.distributionMode = .passThePhone
            dependencies.gameSessionStore.updateSettings(settings)
            distributionMode = .passThePhone
            dependencies.router.navigate(to: .passThePhone)
        }
    }

    private func syncSession() {
        var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        settings.hostIsPlaying = hostIsPlaying
        settings.ghostEnabled = ghostEnabled
        settings.showRoleOnCard = showRoleOnCard
        settings.distributionMode = distributionMode
        dependencies.gameSessionStore.updateSettings(settings)

        var slots: [PlayerSlot] = []

        if settings.hostIsPlaying {
            slots.append(PlayerSlot(
                displayName: "You",
                avatarColor: .blue,
                isHost: true
            ))
        }

        let startIndex = slots.count
        for (offset, name) in playerNames.enumerated() {
            slots.append(PlayerSlot(
                displayName: name,
                avatarColor: AvatarColor.forIndex(startIndex + offset)
            ))
        }

        dependencies.gameSessionStore.setPlayers(slots)
    }
}
