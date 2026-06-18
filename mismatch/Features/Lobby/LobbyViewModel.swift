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
    var ghostPickAgainEnabled: Bool
    var mismatchGhostAlliance: Bool
    var discussionTimerEnabled: Bool
    var timerMinutes: Int
    var distributionMode: DistributionMode
    var cloudGuestVotingEnabled: Bool
    var wordPackSummaries: [WordPackSummary] = []
    var seatedPlayers: [LobbySeatedPlayer]
    var newPlayerName: String = ""
    var savedProfiles: [PlayerProfile] = []
    var isDistributing = false
    var errorMessage: String?
    var showPlayerPicker = false
    var playerPickerTargetId: UUID?
    private var ghostDisabledByUser = false
    private var reservedHostId: UUID?

    private let minimumPlayers = 3

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        let settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        hostIsPlaying = settings.hostIsPlaying
        showRoleOnCard = settings.showRoleOnCard
        ghostEnabled = settings.ghostEnabled
        ghostPickAgainEnabled = settings.ghostPickAgainEnabled
        mismatchGhostAlliance = settings.mismatchGhostAlliance
        discussionTimerEnabled = settings.discussionTimerEnabled
        timerMinutes = Self.resolvedTimerMinutes(from: settings)
        distributionMode = Self.resolvedDistributionMode(settings.distributionMode)
        cloudGuestVotingEnabled = settings.cloudGuestVotingEnabled

        seatedPlayers = Self.loadSeatedPlayers(
            from: dependencies.gameSessionStore.currentSession,
            dependencies: dependencies
        )
        reservedHostId = dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost)?.id

        reconcileHostSeat()
        reloadSavedProfiles()
        syncSession()
        reloadWordPackSummaries()
    }

    func reloadSavedProfiles() {
        savedProfiles = (try? dependencies.profileRepository.fetchAll()) ?? []
    }

    func reloadFromSession() {
        let settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        hostIsPlaying = settings.hostIsPlaying
        showRoleOnCard = settings.showRoleOnCard
        ghostEnabled = settings.ghostEnabled
        ghostPickAgainEnabled = settings.ghostPickAgainEnabled
        mismatchGhostAlliance = settings.mismatchGhostAlliance
        discussionTimerEnabled = settings.discussionTimerEnabled
        timerMinutes = Self.resolvedTimerMinutes(from: settings)
        distributionMode = Self.resolvedDistributionMode(settings.distributionMode)
        cloudGuestVotingEnabled = settings.cloudGuestVotingEnabled
        let playerCount = dependencies.gameSessionStore.currentSession?.players.count ?? 0
        ghostDisabledByUser = playerCount >= RoleDistributionTable.minimumPlayerCountForGhost
            && !settings.ghostEnabled

        seatedPlayers = Self.loadSeatedPlayers(
            from: dependencies.gameSessionStore.currentSession,
            dependencies: dependencies
        )
        reservedHostId = dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost)?.id
        newPlayerName = ""
        isDistributing = false
        errorMessage = nil

        reconcileHostSeat()
        reloadSavedProfiles()
        syncSession()
        reloadWordPackSummaries()
    }

    func reloadWordPackSummaries() {
        let selectedIds = dependencies.gameSessionStore.currentSession?.settings.selectedWordPackIds
            ?? GameSettings.defaultSelectedWordPackIds
        wordPackSummaries = (try? dependencies.wordPairSelector.stats(for: selectedIds)) ?? []
    }

    func toggleWordPack(id: String) {
        var selected = Set(
            dependencies.gameSessionStore.currentSession?.settings.selectedWordPackIds
                ?? GameSettings.defaultSelectedWordPackIds
        )
        if selected.contains(id) {
            selected.remove(id)
            guard !selected.isEmpty else { return }
        } else {
            selected.insert(id)
        }

        var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        settings.selectedWordPackIds = GameSettings.normalizedPackIds(Array(selected))
        dependencies.gameSessionStore.updateSettings(settings)
        reloadWordPackSummaries()
    }

    var selectedWordPackSummary: String {
        let names = wordPackSummaries.filter(\.isSelected).map(\.displayName)
        guard !names.isEmpty else { return "General" }
        if names.count <= 2 {
            return names.joined(separator: " + ")
        }
        return "\(names.prefix(2).joined(separator: " + ")) + \(names.count - 2) more"
    }

    private func selectedWordPackIds() -> [String] {
        let ids = dependencies.gameSessionStore.currentSession?.settings.selectedWordPackIds
            ?? GameSettings.defaultSelectedWordPackIds
        return ids.isEmpty ? GameSettings.defaultSelectedWordPackIds : ids
    }

    private static func loadSeatedPlayers(
        from session: GameSession?,
        dependencies: AppDependencies
    ) -> [LobbySeatedPlayer] {
        let players = session?.players ?? []
        let order = session?.seatingOrderPlayerIds ?? []
        let lookup = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        let ordered = order.compactMap { lookup[$0] } + players.filter { !order.contains($0.id) }

        return ordered.map { player in
            LobbySeatedPlayer(
                id: player.id,
                displayName: resolvedPlayerDisplayName(player, dependencies: dependencies),
                isHost: player.isHost,
                avatarColor: player.avatarColor,
                profileId: player.profileId
            )
        }
    }

    private static func resolvedPlayerDisplayName(
        _ player: PlayerSlot,
        dependencies: AppDependencies
    ) -> String {
        if player.isHost, player.displayName == "You" || player.displayName.isEmpty {
            return dependencies.hostPreferencesStore.load().resolvedHostDisplayName
        }
        return player.displayName
    }

    private var preferredHostDisplayName: String {
        dependencies.hostPreferencesStore.load().resolvedHostDisplayName
    }

    private func resolvedPlayerDisplayName(_ player: PlayerSlot) -> String {
        Self.resolvedPlayerDisplayName(player, dependencies: dependencies)
    }

    func openChangePlayerPicker(for playerId: UUID) {
        playerPickerTargetId = playerId
        showPlayerPicker = true
    }

    func dismissPlayerPicker() {
        showPlayerPicker = false
        playerPickerTargetId = nil
    }

    func addPlayer(from profile: PlayerProfile) {
        guard !isProfileSeated(profile.id, excludingPlayerId: playerPickerTargetId) else {
            errorMessage = "\(profile.name) is already in this game."
            return
        }

        if let targetId = playerPickerTargetId {
            assignProfile(profile, to: targetId)
        } else {
            seatedPlayers.append(
                LobbySeatedPlayer(
                    id: UUID(),
                    displayName: profile.name,
                    isHost: false,
                    avatarColor: profile.avatarColor,
                    profileId: profile.id
                )
            )
        }

        errorMessage = nil
        dismissPlayerPicker()
        newPlayerName = ""
        reloadSavedProfiles()
        syncSession()
    }

    func selectSuggestedProfile(_ profile: PlayerProfile) {
        addPlayer(from: profile)
    }

    func addNewPlayer(named name: String) {
        do {
            let profile = try dependencies.profileRepository.findOrCreate(
                name: name,
                avatarColor: AvatarColor.forIndex(seatedPlayers.count)
            )
            addPlayer(from: profile)
        } catch {
            errorMessage = "Could not add player."
        }
    }

    func availableProfilesForPicker() -> [PlayerProfile] {
        (try? dependencies.profileRepository.fetchAll()) ?? []
    }

    var excludedProfileIdsForPicker: Set<UUID> {
        let seated = Set(seatedPlayers.compactMap(\.profileId))
        guard let targetId = playerPickerTargetId,
              let currentProfileId = seatedPlayers.first(where: { $0.id == targetId })?.profileId else {
            return seated
        }
        return seated.subtracting([currentProfileId])
    }

    var playerPickerAllowsHostSelection: Bool {
        guard let targetId = playerPickerTargetId else { return false }
        return seatedPlayers.first(where: { $0.id == targetId })?.isHost == true
    }

    private func assignProfile(_ profile: PlayerProfile, to playerId: UUID) {
        guard let index = seatedPlayers.firstIndex(where: { $0.id == playerId }) else { return }
        seatedPlayers[index].profileId = profile.id
        seatedPlayers[index].avatarColor = profile.avatarColor
        if !seatedPlayers[index].isHost {
            seatedPlayers[index].displayName = profile.name
        }
    }

    private func isProfileSeated(_ profileId: UUID, excludingPlayerId: UUID?) -> Bool {
        seatedPlayers.contains { player in
            player.profileId == profileId && player.id != excludingPlayerId
        }
    }

    private func ensureProfilesForAllPlayers() {
        for index in seatedPlayers.indices {
            guard seatedPlayers[index].profileId == nil else { continue }
            guard !seatedPlayers[index].isHost else { continue }

            guard let profile = try? dependencies.profileRepository.findOrCreate(
                name: seatedPlayers[index].displayName,
                avatarColor: seatedPlayers[index].avatarColor
            ) else { continue }

            seatedPlayers[index].profileId = profile.id
            seatedPlayers[index].avatarColor = profile.avatarColor
            seatedPlayers[index].displayName = profile.name
        }
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

    var showsProfileSuggestions: Bool {
        newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
    }

    var profileSuggestions: [PlayerProfile] {
        let query = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else { return [] }

        let seatedProfileIds = Set(seatedPlayers.compactMap(\.profileId))
        return savedProfiles.filter { profile in
            !seatedProfileIds.contains(profile.id) && Self.profileNameMatchesSearch(profile.name, query: query)
        }
    }

    var canContinue: Bool {
        totalPlayerCount >= minimumPlayers
            && !isDistributing
            && wordPackSummaries.contains(where: \.isSelected)
    }

    var statusMessage: String {
        let playerLine: String
        if hostIsPlaying {
            let hostName = seatedPlayers.first(where: \.isHost)?.displayName ?? preferredHostDisplayName
            playerLine = "\(totalPlayerCount) players · \(hostName) + \(guestCount) guest\(guestCount == 1 ? "" : "s")"
        } else {
            playerLine = "\(totalPlayerCount) of \(minimumPlayers)+ players"
        }

        let gamesPlayed = dependencies.gameSessionStore.gamesPlayedCount
        guard gamesPlayed > 0 else { return playerLine }
        return "\(GameProgressCopy.gamesPlayedLabel(gamesPlayed)) · \(playerLine)"
    }

    var rulesSummary: String {
        var parts = [selectedWordPackSummary, distributionMode.displayName]
        if hostIsPlaying { parts.append("You're playing") }
        if ghostEnabled { parts.append("Ghost") }
        if ghostEnabled && ghostPickAgainEnabled { parts.append("Ghost pick again") }
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
        addNewPlayer(named: trimmed)
    }

    func removePlayer(id: UUID) {
        seatedPlayers.removeAll { $0.id == id && !$0.isHost }
        syncSession()
    }

    func updatePlayer(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = seatedPlayers.firstIndex(where: { $0.id == id && !$0.isHost }) else { return }

        seatedPlayers[index].displayName = trimmed

        if let profileId = seatedPlayers[index].profileId {
            try? dependencies.profileRepository.update(
                id: profileId,
                name: trimmed,
                avatarColor: seatedPlayers[index].avatarColor
            )
        } else if let profile = try? dependencies.profileRepository.findOrCreate(
            name: trimmed,
            avatarColor: seatedPlayers[index].avatarColor
        ) {
            seatedPlayers[index].profileId = profile.id
            seatedPlayers[index].avatarColor = profile.avatarColor
            seatedPlayers[index].displayName = profile.name
        }

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
        ensureProfilesForAllPlayers()
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
            let selection = try dependencies.wordPairSelector.nextPair(packIds: selectedWordPackIds())
            try dependencies.gameSessionStore.distributeRoles(wordPair: selection.pair)
            dependencies.wordPairSelector.markUsed(selection)
            reloadWordPackSummaries()

            switch distributionMode {
            case .passThePhone:
                dependencies.router.navigate(to: .passThePhone)
            case .cloudQR:
                await startCloudQRDistribution()
            }
        } catch WordPairSelectorError.noPairsAvailable, WordPairSelectorError.noPacksSelected {
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
        let hostName = preferredHostDisplayName
        if hostIsPlaying {
            if let index = seatedPlayers.firstIndex(where: \.isHost) {
                reservedHostId = seatedPlayers[index].id
                if seatedPlayers[index].displayName == "You" || seatedPlayers[index].displayName.isEmpty {
                    seatedPlayers[index].displayName = hostName
                }
                return
            }
            let hostId = reservedHostId ?? UUID()
            reservedHostId = hostId
            seatedPlayers.insert(
                LobbySeatedPlayer(
                    id: hostId,
                    displayName: hostName,
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
        settings.ghostPickAgainEnabled = ghostPickAgainEnabled
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
        let sessionState = dependencies.gameSessionStore.currentSession?.state

        let slots = seatedPlayers.map { entry in
            var slot = PlayerSlot(
                id: entry.id,
                displayName: entry.displayName,
                avatarColor: entry.avatarColor,
                isHost: entry.isHost,
                profileId: entry.profileId
            )
            if let existing = existingById[entry.id] {
                slot.sessionScore = existing.sessionScore
                if sessionState != .lobby {
                    slot.assignment = existing.assignment
                    slot.hasOpenedCard = existing.hasOpenedCard
                    slot.pickedCardIndex = existing.pickedCardIndex
                    slot.isEliminated = existing.isEliminated
                    slot.cardToken = existing.cardToken
                    slot.cardURL = existing.cardURL
                }
            }
            return slot
        }

        dependencies.gameSessionStore.setPlayers(slots)
        dependencies.gameSessionStore.setSeatingOrder(seatedPlayers.map(\.id))
    }

    private static func profileNameMatchesSearch(_ name: String, query: String) -> Bool {
        name.range(of: query, options: .caseInsensitive) != nil
    }
}
