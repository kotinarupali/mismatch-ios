import Foundation

@MainActor
@Observable
final class MyCardViewModel {
    private let dependencies: AppDependencies

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

    func markOpened() {
        guard let hostId = dependencies.gameSessionStore.currentSession?.players
            .first(where: \.isHost)?.id else { return }
        dependencies.gameSessionStore.markCardOpened(playerId: hostId, cardIndex: 0)
    }
}
