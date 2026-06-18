import Foundation

@MainActor
@Observable
final class DiscussionViewModel {
    private let dependencies: AppDependencies
    let timerService: TimerService

    let timerDurationSeconds: Int
    var selectedPlayerId: UUID?
    var showConfirmDialog = false
    var showPlayerRolePicker = false
    var playerToReveal: PlayerSlot?
    var guestVoteTallies: [UUID: Int] = [:]
    var isStartingRevote = false

    private var votePollTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        self.timerService = dependencies.timerService
        timerDurationSeconds = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
    }

    var timerEnabled: Bool {
        dependencies.gameSessionStore.currentSession?.settings.discussionTimerEnabled ?? false
    }

    var ghostEnabled: Bool {
        dependencies.gameSessionStore.currentSession?.settings.ghostEnabled ?? false
    }

    var cloudGuestVotingEnabled: Bool {
        guard let session = dependencies.gameSessionStore.currentSession else { return false }
        return session.settings.cloudGuestVotingEnabled
            && session.cardDeliveryBackend == .cloud
            && session.joinSessionToken != nil
            && session.cloudHostKey != nil
    }

    var showsGuestVoteTallies: Bool {
        cloudGuestVotingEnabled && !guestVoteTallies.isEmpty
    }

    var guestVoteTie: GuestVoteTie? {
        guard cloudGuestVotingEnabled else { return nil }
        let activeIds = Set(activePlayers.map(\.id))
        return GuestVoteTieDetector.detect(tallies: guestVoteTallies, activePlayerIds: activeIds)
    }

    var tiedPlayerNamesLabel: String? {
        guard let tie = guestVoteTie else { return nil }
        let names = tie.tiedPlayerIds.compactMap { id in
            allPlayers.first(where: { $0.id == id }).map { $0.isHost ? "You" : $0.displayName }
        }
        guard !names.isEmpty else { return nil }
        return names.formatted(.list(type: .and))
    }

    var showsRevotePrompt: Bool {
        guestVoteTie != nil
    }

    var allPlayers: [PlayerSlot] {
        dependencies.gameSessionStore.seatingOrderPlayers()
    }

    var displayPlayers: [PlayerSlot] {
        guard let starterId = discussionStarterId,
              let startIndex = allPlayers.firstIndex(where: { $0.id == starterId }) else {
            return allPlayers
        }
        return Array(allPlayers[startIndex...] + allPlayers[..<startIndex])
    }

    var discussionStarterId: UUID? {
        dependencies.gameSessionStore.discussionStarter?.id
    }

    var discussionStarterName: String? {
        guard let player = dependencies.gameSessionStore.discussionStarter else { return nil }
        return player.isHost ? "You" : player.displayName
    }

    var activePlayers: [PlayerSlot] {
        allPlayers.filter { !$0.isEliminated }
    }

    var playersWithPickedCards: [PlayerSlot] {
        dependencies.gameSessionStore.playersWithPickedCards()
    }

    var remainingMismatchCount: Int {
        dependencies.gameSessionStore.remainingOutsiderCounts().mismatch
    }

    var remainingGhostCount: Int {
        dependencies.gameSessionStore.remainingOutsiderCounts().ghost
    }

    var selectedPlayerName: String {
        guard let id = selectedPlayerId,
              let player = allPlayers.first(where: { $0.id == id }) else {
            return "this player"
        }
        return player.isHost ? "You" : player.displayName
    }

    var canConfirmVote: Bool {
        guard let id = selectedPlayerId else { return false }
        return activePlayers.contains { $0.id == id }
    }

    func onAppear() {
        dependencies.gameSessionStore.updateState(.discussing)
        if let id = selectedPlayerId,
           allPlayers.first(where: { $0.id == id })?.isEliminated == true {
            selectedPlayerId = nil
        }
        guard timerEnabled else {
            startCloudGuestVotingIfNeeded()
            return
        }
        let duration = dependencies.gameSessionStore.currentSession?.settings.timerSeconds ?? 180
        dependencies.timerService.start(durationSeconds: duration) { [weak self] in
            self?.dependencies.timerService.stop()
        }
        startCloudGuestVotingIfNeeded()
    }

    func onDisappear() {
        dependencies.timerService.stop()
        stopGuestVotePolling()
    }

    func selectPlayer(_ id: UUID) {
        guard allPlayers.first(where: { $0.id == id && !$0.isEliminated }) != nil else { return }
        selectedPlayerId = id
    }

    func confirmVoteTapped() {
        guard let id = selectedPlayerId,
              allPlayers.first(where: { $0.id == id && !$0.isEliminated }) != nil else { return }
        showConfirmDialog = true
    }

    func startRevoteTapped() {
        guard guestVoteTie != nil, !isStartingRevote else { return }
        Task { await startRevote() }
    }

    func submitElimination() {
        guard let id = selectedPlayerId else { return }
        dependencies.timerService.stop()
        dependencies.gameSessionStore.eliminate(playerId: id)
        Task { await closeCloudGuestVoting() }
        dependencies.router.navigate(to: .results)
    }

    func checkPlayerRoleTapped() {
        showPlayerRolePicker = true
    }

    func selectPlayerForRoleCheck(_ player: PlayerSlot) {
        playerToReveal = player
    }

    func repickRoles() {
        stopGuestVotePolling()
        dependencies.repickRoles()
    }

    func endSessionTapped() {
        stopGuestVotePolling()
        dependencies.showSessionSummary()
    }

    func endGame() {
        endSessionTapped()
    }

    var gameSessionStore: GameSessionStore {
        dependencies.gameSessionStore
    }

    private func startCloudGuestVotingIfNeeded() {
        guard cloudGuestVotingEnabled else { return }

        Task { await openCloudGuestVoting() }
        startGuestVotePolling()
    }

    private func startGuestVotePolling() {
        stopGuestVotePolling()
        votePollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, self.cloudGuestVotingEnabled else { continue }
                await self.refreshGuestVoteTallies()
            }
        }
    }

    private func stopGuestVotePolling() {
        votePollTask?.cancel()
        votePollTask = nil
    }

    private func openCloudGuestVoting() async {
        guard let session = dependencies.gameSessionStore.currentSession,
              let token = session.joinSessionToken,
              let hostKey = session.cloudHostKey else { return }

        let eliminatedIds = session.players.filter(\.isEliminated).map(\.id)
        try? await dependencies.remoteCardSessionClient.controlVoting(
            token: token,
            hostKey: hostKey,
            action: .open,
            eliminatedPlayerIds: eliminatedIds
        )
        await refreshGuestVoteTallies()
    }

    private func closeCloudGuestVoting() async {
        guard let session = dependencies.gameSessionStore.currentSession,
              let token = session.joinSessionToken,
              let hostKey = session.cloudHostKey else { return }

        let eliminatedIds = session.players.filter(\.isEliminated).map(\.id)
        try? await dependencies.remoteCardSessionClient.controlVoting(
            token: token,
            hostKey: hostKey,
            action: .close,
            eliminatedPlayerIds: eliminatedIds
        )
        guestVoteTallies = [:]
    }

    private func refreshGuestVoteTallies() async {
        guard let token = dependencies.gameSessionStore.currentSession?.joinSessionToken else { return }
        guard let snapshot = try? await dependencies.remoteCardSessionClient.fetchSnapshot(token: token) else {
            return
        }
        guestVoteTallies = snapshot.voteTalliesByPlayerId
    }

    private func startRevote() async {
        guard let tie = guestVoteTie else { return }
        guard let session = dependencies.gameSessionStore.currentSession,
              let token = session.joinSessionToken,
              let hostKey = session.cloudHostKey else { return }

        isStartingRevote = true
        defer { isStartingRevote = false }

        let eliminatedIds = session.players.filter(\.isEliminated).map(\.id)
        do {
            try await dependencies.remoteCardSessionClient.controlVoting(
                token: token,
                hostKey: hostKey,
                action: .revote,
                eliminatedPlayerIds: eliminatedIds,
                revoteExcludedPlayerIds: tie.tiedPlayerIds
            )
            selectedPlayerId = nil
            await refreshGuestVoteTallies()
        } catch {
            // Keep current tallies; host can retry or pick manually.
        }
    }
}
