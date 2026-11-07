import Foundation

@MainActor
@Observable
final class MyCardViewModel {
    let dependencies: AppDependencies

    private var refreshTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    var showRoleOnCard: Bool {
        dependencies.gameSessionStore.currentSession?.settings.showRoleOnCard ?? false
    }

    var assignment: RoleAssignment? {
        dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?
            .assignment
    }

    var faceDownCardCount: Int {
        CardPickRules.faceDownCardCount(
            playerCount: dependencies.gameSessionStore.currentSession?.players.count ?? 3
        )
    }

    var insiderWord: String? {
        dependencies.gameSessionStore.insiderWord
    }

    var claimedCards: [ClaimedCard] {
        dependencies.gameSessionStore.claimedCards()
    }

    var lockedCardIndex: Int? {
        guard let host = dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost),
              host.hasOpenedCard,
              let index = host.pickedCardIndex else { return nil }
        return index
    }

    var hostHasPicked: Bool {
        dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?
            .hasOpenedCard ?? false
    }

    var canGhostRoleSwap: Bool {
        guard let hostId = dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?.id else { return false }
        return dependencies.gameSessionStore.canSwapGhostRole(from: hostId)
    }

    func swapGhostRole() -> RoleAssignment? {
        guard let session = dependencies.gameSessionStore.currentSession,
              let hostId = session.players.first(where: \.isHost)?.id else { return nil }
        guard let swapped = dependencies.gameSessionStore.swapGhostRoleAway(from: hostId) else { return nil }
        dependencies.gameSessionStore.clearPickedCardIndex(for: hostId)

        if session.cardDeliveryBackend == .cloud,
           let token = session.joinSessionToken {
            let hostKey = session.cloudHostKey
            Task { [dependencies] in
                try? await dependencies.remoteCardSessionClient.swapGhostRole(
                    token: token,
                    playerId: hostId,
                    hostKey: hostKey
                )
                guard let latest = dependencies.gameSessionStore.currentSession,
                      let host = latest.players.first(where: \.isHost),
                      host.hasOpenedCard,
                      let cardIndex = host.pickedCardIndex,
                      let assignment = host.assignment,
                      let hostKey else { return }
                try? await dependencies.remoteCardSessionClient.hostOpenedCard(
                    token: token,
                    hostKey: hostKey,
                    playerId: host.id,
                    cardIndex: cardIndex,
                    role: assignment.role.rawValue,
                    word: assignment.word,
                    categoryHint: assignment.categoryHint
                )
            }
        }

        return swapped
    }

    func startCloudClaimRefresh() {
        guard dependencies.gameSessionStore.currentSession?.cardDeliveryBackend == .cloud,
              let token = dependencies.gameSessionStore.currentSession?.joinSessionToken else { return }

        refreshTask?.cancel()
        refreshTask = Task { [dependencies] in
            while !Task.isCancelled {
                do {
                    let snapshot = try await dependencies.remoteCardSessionClient.fetchSnapshot(token: token)
                    dependencies.gameSessionStore.applyRemoteCardSnapshot(snapshot)
                } catch {
                    // Keep polling while the host is picking.
                }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    func stopCloudClaimRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    /// Locks the host's card as soon as they see it, so a later Ghost re-pick cannot replace it.
    func hostSawCard(cardIndex: Int) {
        guard let session = dependencies.gameSessionStore.currentSession,
              let host = session.players.first(where: \.isHost),
              let assignment = host.assignment else { return }

        dependencies.gameSessionStore.markCardOpened(playerId: host.id, cardIndex: cardIndex)

        guard session.cardDeliveryBackend == .cloud,
              let token = session.joinSessionToken,
              let hostKey = session.cloudHostKey else { return }

        let playerId = host.id
        let role = assignment.role.rawValue
        let word = assignment.word
        let hint = assignment.categoryHint
        Task { [dependencies] in
            try? await dependencies.remoteCardSessionClient.hostOpenedCard(
                token: token,
                hostKey: hostKey,
                playerId: playerId,
                cardIndex: cardIndex,
                role: role,
                word: word,
                categoryHint: hint
            )
        }
    }

    func markOpened(cardIndex: Int, attemptedGhostRoleSwap: Bool = false) {
        guard let hostId = dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?.id else { return }

        if attemptedGhostRoleSwap,
           dependencies.gameSessionStore.currentSession?.players.first(where: { $0.id == hostId })?.assignment?.role == .ghost {
            _ = swapGhostRole()
        }

        dependencies.gameSessionStore.markCardOpened(playerId: hostId, cardIndex: cardIndex)
    }
}
