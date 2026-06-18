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

    var hostHasPicked: Bool {
        dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?
            .hasOpenedCard ?? false
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

    func markOpened(cardIndex: Int) {
        guard let hostId = dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?.id else { return }
        dependencies.gameSessionStore.markCardOpened(playerId: hostId, cardIndex: cardIndex)
    }
}
