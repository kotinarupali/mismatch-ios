import Foundation

struct LobbySeatedPlayer: Identifiable, Equatable {
    let id: UUID
    var displayName: String
    var isHost: Bool
    var avatarColor: AvatarColor
    var profileId: UUID?
}

@MainActor
@Observable
final class LobbyViewModel {
    private let dependencies: AppDependencies

    var hostIsPlaying: Bool
    var showRoleOnCard: Bool
    var ghostEnabled: Bool
    var mismatchGhostAlliance: Bool
    var discussionTimerEnabled: Bool
    var timerMinutes: Int
    var distributionMode: DistributionMode
    var cloudGuestVotingEnabled: Bool
    var seatedPlayers: [LobbySeatedPlayer]
    var newPlayerName: String = ""
    var isDistributing = false
    var errorMessage: String?
    var showProfilePicker = false
    var profilePickerPlayerId: UUID?
    private var ghostDisabledByUser = false
    private var reservedHostId: UUID?

    private let minimumPlayers = 3

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        let settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        hostIsPlaying = settings.hostIsPlaying
        showRoleOnCard = settings.showRoleOnCard
        ghostEnabled = settings.ghostEnabled
        mismatchGhostAlliance = settings.mismatchGhostAlliance
        discussionTimerEnabled = settings.discussionTimerEnabled
        timerMinutes = Self.resolvedTimerMinutes(from: settings)
        distributionMode = Self.resolvedDistributionMode(settings.distributionMode)
        cloudGuestVotingEnabled = settings.cloudGuestVotingEnabled

        seatedPlayers = Self.loadSeatedPlayers(from: dependencies.gameSessionStore.currentSession)
        reservedHostId = dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost)?.id

        reconcileHostSeat()
        syncSession()
    }

    func reloadFromSession() {
        let settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        hostIsPlaying = settings.hostIsPlaying
        showRoleOnCard = settings.showRoleOnCard
        ghostEnabled = settings.ghostEnabled
        mismatchGhostAlliance = settings.mismatchGhostAlliance
        discussionTimerEnabled = settings.discussionTimerEnabled
        timerMinutes = Self.resolvedTimerMinutes(from: settings)
        distributionMode = Self.resolvedDistributionMode(settings.distributionMode)
        cloudGuestVotingEnabled = settings.cloudGuestVotingEnabled
        let playerCount = dependencies.gameSessionStore.currentSession?.players.count ?? 0
        ghostDisabledByUser = playerCount >= RoleDistributionTable.minimumPlayerCountForGhost
            && !settings.ghostEnabled

        seatedPlayers = Self.loadSeatedPlayers(from: dependencies.gameSessionStore.currentSession)
        reservedHostId = dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost)?.id
        newPlayerName = ""
        isDistributing = false
        errorMessage = nil

        reconcileHostSeat()
        syncSession()
    }

    private static func loadSeatedPlayers(from session: GameSession?) -> [LobbySeatedPlayer] {
        let players = session?.players ?? []
        let order = session?.seatingOrderPlayerIds ?? []
        let lookup = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        let ordered = order.compactMap { lookup[$0] } + players.filter { !order.contains($0.id) }

        return ordered.map { player in
            LobbySeatedPlayer(
                id: player.id,
                displayName: player.isHost ? "You" : player.displayName,
                isHost: player.isHost,
                avatarColor: player.avatarColor,
                profileId: player.profileId
            )
        }
    }

    func openProfilePicker(for playerId: UUID) {
        profilePickerPlayerId = playerId
        showProfilePicker = true
    }

    func linkProfile(_ profile: PlayerProfile, to playerId: UUID) {
        guard let index = seatedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        seatedPlayers[index].profileId = profile.id
        seatedPlayers[index].avatarColor = profile.avatarColor
        if !seatedPlayers[index].isHost {
            seatedPlayers[index].displayName = profile.name
        }
        syncSession()
    }

    func unlinkProfile(from playerId: UUID) {
        guard let index = seatedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        seatedPlayers[index].profileId = nil
        syncSession()
    }

    func dismissProfilePicker() {
        showProfilePicker = false
        profilePickerPlayerId = nil
    }

    func completeProfileSelection(_ profile: PlayerProfile?) {
        guard let playerId = profilePickerPlayerId else { return }
        if let profile {
            linkProfile(profile, to: playerId)
        } else {
            unlinkProfile(from: playerId)
        }
        dismissProfilePicker()
    }

    var linkedProfileIdForPicker: UUID? {
        guard let playerId = profilePickerPlayerId else { return nil }
        return seatedPlayers.first(where: { $0.id == playerId })?.profileId
    }

    var totalPlayerCount: Int {
        seatedPlayers.count
    }

    var guestsNeeded: Int {
        max(0, minimumPlayers - (hostIsPlaying ? 1 : 0))
    }

    var guestCount: Int {
        seatedPlayers.filter { !$0.isHost }.count
    }

    var canAddPlayer: Bool {
        !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canContinue: Bool {
        totalPlayerCount >= minimumPlayers && !isDistributing
    }

    var statusMessage: String {
        let playerLine: String
        if hostIsPlaying {
            playerLine = "\(totalPlayerCount) players · you + \(guestCount) guest\(guestCount == 1 ? "" : "s")"
        } else {
            playerLine = "\(totalPlayerCount) of \(minimumPlayers)+ players"
        }

        let gamesPlayed = dependencies.gameSessionStore.gamesPlayedCount
        guard gamesPlayed > 0 else { return playerLine }
        return "\(GameProgressCopy.gamesPlayedLabel(gamesPlayed)) · \(playerLine)"
    }

    var rulesSummary: String {
        var parts = [distributionMode.displayName]
        if hostIsPlaying { parts.append("You're playing") }
        if ghostEnabled { parts.append("Ghost") }
        if mismatchGhostAlliance { parts.append("Alliance") }
        if showRoleOnCard { parts.append("Roles on card") }
        if discussionTimerEnabled { parts.append("\(timerMinutes) min timer") }
        if distributionMode == .cloudQR, cloudGuestVotingEnabled { parts.append("Guest voting") }
        return parts.joined(separator: " · ")
    }

    var showsCloudGuestVotingToggle: Bool {
        distributionMode == .cloudQR && CloudCardConfig.isConfigured
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

    var canToggleGhost: Bool {
        totalPlayerCount >= RoleDistributionTable.minimumPlayerCountForGhost
    }

    func refreshSession() {
        reconcileHostSeat()
        syncSession()
    }

    func setGhostEnabled(_ enabled: Bool) {
        if totalPlayerCount >= RoleDistributionTable.minimumPlayerCountForGhost {
            ghostDisabledByUser = !enabled
        }
        ghostEnabled = enabled
        syncSession()
    }

    private func applyAutomaticGhostIfNeeded() {
        guard totalPlayerCount >= RoleDistributionTable.minimumPlayerCountForGhost else {
            ghostEnabled = false
            return
        }
        if !ghostDisabledByUser {
            ghostEnabled = true
        }
    }

    func addPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        seatedPlayers.append(
            LobbySeatedPlayer(
                id: UUID(),
                displayName: trimmed,
                isHost: false,
                avatarColor: AvatarColor.forIndex(seatedPlayers.count)
            )
        )
        newPlayerName = ""
        syncSession()
    }

    func removePlayer(id: UUID) {
        seatedPlayers.removeAll { $0.id == id && !$0.isHost }
        syncSession()
    }

    func updatePlayer(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = seatedPlayers.firstIndex(where: { $0.id == id && !$0.isHost }) else { return }

        var updatedPlayers = seatedPlayers
        updatedPlayers[index].displayName = trimmed
        seatedPlayers = updatedPlayers
        syncSession()
    }

    func moveSeatedPlayerUp(at index: Int) {
        guard seatedPlayers.indices.contains(index), index > 0 else { return }
        seatedPlayers.swapAt(index, index - 1)
        syncSession()
    }

    func moveSeatedPlayerDown(at index: Int) {
        guard seatedPlayers.indices.contains(index), index < seatedPlayers.count - 1 else { return }
        seatedPlayers.swapAt(index, index + 1)
        syncSession()
    }

    var playersShortfallMessage: String? {
        let shortfall = guestsNeeded - guestCount
        guard shortfall > 0 else { return nil }

        if guestCount == 0 && !hostIsPlaying {
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
            let wordPair = try dependencies.wordPairSelector.nextPair()
            try dependencies.gameSessionStore.distributeRoles(wordPair: wordPair)
            dependencies.wordPairSelector.markUsed(wordPair)

            switch distributionMode {
            case .passThePhone:
                dependencies.router.navigate(to: .passThePhone)
            case .cloudQR:
                await startCloudQRDistribution()
            }
        } catch WordPairSelectorError.noPairsAvailable {
            errorMessage = "No word pairs available."
        } catch {
            errorMessage = "Could not distribute roles."
        }
    }

    private func startCloudQRDistribution() async {
        guard let session = dependencies.gameSessionStore.currentSession else { return }

        do {
            let result = try await dependencies.remoteCardSessionClient.createSession(from: session)
            dependencies.gameSessionStore.setSharedJoinURL(
                result.joinURL,
                sessionToken: result.sessionToken,
                hostKey: result.hostKey,
                backend: .cloud
            )
            dependencies.router.navigate(to: .qrGrid)
        } catch {
            fallbackFromQRDistribution(message: "Cloud cards unavailable. Switching to pass-the-phone.")
        }
    }

    private func fallbackFromQRDistribution(message: String) {
        errorMessage = message
        var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        settings.distributionMode = .passThePhone
        dependencies.gameSessionStore.updateSettings(settings)
        distributionMode = .passThePhone
        dependencies.router.navigate(to: .passThePhone)
    }

    private static func resolvedDistributionMode(_ mode: DistributionMode) -> DistributionMode {
        if mode == .cloudQR, !CloudCardConfig.isConfigured {
            return .passThePhone
        }
        return mode
    }

    private static func resolvedTimerMinutes(from settings: GameSettings) -> Int {
        let minutes = max(1, settings.timerSeconds / 60)
        return HostPreferences.allowedTimerMinutes.contains(minutes)
            ? minutes
            : HostPreferences.default.timerMinutes
    }

    private func reconcileHostSeat() {
        if hostIsPlaying {
            if seatedPlayers.contains(where: \.isHost) { return }
            let hostId = reservedHostId ?? UUID()
            reservedHostId = hostId
            seatedPlayers.insert(
                LobbySeatedPlayer(
                    id: hostId,
                    displayName: "You",
                    isHost: true,
                    avatarColor: .blue
                ),
                at: 0
            )
        } else if let host = seatedPlayers.first(where: \.isHost) {
            reservedHostId = host.id
            seatedPlayers.removeAll(where: \.isHost)
        }
    }

    private func syncSession() {
        applyAutomaticGhostIfNeeded()

        var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        settings.hostIsPlaying = hostIsPlaying
        settings.ghostEnabled = ghostEnabled
        settings.mismatchGhostAlliance = mismatchGhostAlliance
        settings.discussionTimerEnabled = discussionTimerEnabled
        settings.timerSeconds = timerMinutes * 60
        settings.showRoleOnCard = showRoleOnCard
        settings.distributionMode = distributionMode
        settings.cloudGuestVotingEnabled = distributionMode == .cloudQR && cloudGuestVotingEnabled
        dependencies.gameSessionStore.updateSettings(settings)

        let existingById = Dictionary(
            uniqueKeysWithValues: (dependencies.gameSessionStore.currentSession?.players ?? []).map { ($0.id, $0) }
        )

        let slots = seatedPlayers.map { entry in
            var slot = PlayerSlot(
                id: entry.id,
                displayName: entry.isHost ? "You" : entry.displayName,
                avatarColor: entry.avatarColor,
                isHost: entry.isHost,
                profileId: entry.profileId
            )
            if let existing = existingById[entry.id] {
                slot.assignment = existing.assignment
                slot.hasOpenedCard = existing.hasOpenedCard
                slot.pickedCardIndex = existing.pickedCardIndex
                slot.isEliminated = existing.isEliminated
                slot.cardToken = existing.cardToken
                slot.cardURL = existing.cardURL
                slot.sessionScore = existing.sessionScore
            }
            return slot
        }

        dependencies.gameSessionStore.setPlayers(slots)
        dependencies.gameSessionStore.setSeatingOrder(seatedPlayers.map(\.id))
    }
}
