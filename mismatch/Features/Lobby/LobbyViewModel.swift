import Foundation

@MainActor
@Observable
final class LobbyViewModel {
    private let dependencies: AppDependencies

    var hostIsPlaying: Bool
    var showRoleOnCard: Bool
    var ghostEnabled: Bool
    var mismatchGhostAlliance: Bool
    var discussionTimerEnabled: Bool
    var distributionMode: DistributionMode
    var playerNames: [String]
    var newPlayerName: String = ""
    var isDistributing = false
    var errorMessage: String?

    private let minimumPlayers = 3

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        let settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        hostIsPlaying = settings.hostIsPlaying
        showRoleOnCard = settings.showRoleOnCard
        ghostEnabled = settings.ghostEnabled
        mismatchGhostAlliance = settings.mismatchGhostAlliance
        discussionTimerEnabled = settings.discussionTimerEnabled
        distributionMode = settings.distributionMode
        playerNames = dependencies.gameSessionStore.currentSession?.players
            .filter { !$0.isHost }
            .map(\.displayName) ?? []
    }

    var totalPlayerCount: Int {
        playerNames.count + (hostIsPlaying ? 1 : 0)
    }

    var guestsNeeded: Int {
        max(0, minimumPlayers - (hostIsPlaying ? 1 : 0))
    }

    var canAddPlayer: Bool {
        !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canContinue: Bool {
        totalPlayerCount >= minimumPlayers && !isDistributing
    }

    var statusMessage: String {
        if hostIsPlaying {
            return "\(totalPlayerCount) players · you + \(playerNames.count) guest\(playerNames.count == 1 ? "" : "s")"
        }
        return "\(totalPlayerCount) of \(minimumPlayers)+ players"
    }

    var rulesSummary: String {
        var parts = [distributionMode.displayName]
        if hostIsPlaying { parts.append("You're playing") }
        if ghostEnabled { parts.append("Ghost") }
        if mismatchGhostAlliance { parts.append("Alliance") }
        if showRoleOnCard { parts.append("Roles on card") }
        if discussionTimerEnabled { parts.append("Timer") }
        return parts.joined(separator: " · ")
    }

    var projectedMismatchCount: Int {
        RoleDistributionTable.counts(
            playerCount: totalPlayerCount,
            ghostEnabled: ghostEnabled
        ).mismatch
    }

    var projectedGhostCount: Int {
        RoleDistributionTable.counts(
            playerCount: totalPlayerCount,
            ghostEnabled: ghostEnabled
        ).ghost
    }

    var showsProjectedRoleCounts: Bool {
        totalPlayerCount >= minimumPlayers
    }

    var playerColors: [AvatarColor] {
        let start = hostIsPlaying ? 1 : 0
        return playerNames.enumerated().map { AvatarColor.forIndex(start + $0.offset) }
    }

    func refreshSession() {
        syncSession()
    }

    func addPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        playerNames.append(trimmed)
        newPlayerName = ""
        syncSession()
    }

    func removePlayer(at index: Int) {
        guard playerNames.indices.contains(index) else { return }
        playerNames.remove(at: index)
        syncSession()
    }

    func updatePlayer(at index: Int, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard playerNames.indices.contains(index), !trimmed.isEmpty else { return }
        playerNames[index] = trimmed
        syncSession()
    }

    var playersShortfallMessage: String? {
        let shortfall = guestsNeeded - playerNames.count
        guard shortfall > 0 else { return nil }

        if playerNames.isEmpty && !hostIsPlaying {
            return "Add at least \(guestsNeeded) players to start."
        }
        return "Add \(shortfall) more guest\(shortfall == 1 ? "" : "s") to reach \(minimumPlayers) players."
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
        settings.mismatchGhostAlliance = mismatchGhostAlliance
        settings.discussionTimerEnabled = discussionTimerEnabled
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
