import Foundation

@MainActor
@Observable
final class PassThePhoneViewModel {
    private let dependencies: AppDependencies

    private var passOrder: [PlayerSlot] = []
    private var currentIndex = 0

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        passOrder = dependencies.gameSessionStore.passThePhoneOrder()
            .filter { $0.assignment != nil && !$0.hasOpenedCard }
        if passOrder.isEmpty {
            passOrder = dependencies.gameSessionStore.passThePhoneOrder()
                .filter { $0.assignment != nil }
            currentIndex = passOrder.count
        }
    }

    var title: String {
        guard currentPlayer != nil else { return "All roles revealed" }
        return "Pass the phone"
    }

    var subtitle: String {
        guard let player = currentPlayer else {
            return "Everyone has seen their card."
        }
        return "Pass to \(player.isHost ? "You" : player.displayName)"
    }

    var showRoleOnCard: Bool {
        dependencies.gameSessionStore.currentSession?.settings.showRoleOnCard ?? false
    }

    var currentAssignment: RoleAssignment? {
        currentPlayer?.assignment
    }

    private var currentPlayer: PlayerSlot? {
        guard currentIndex < passOrder.count else { return nil }
        return passOrder[currentIndex]
    }

    func cardCompleted() {
        guard let player = currentPlayer else { return }
        dependencies.gameSessionStore.markCardOpened(playerId: player.id)
        currentIndex += 1

        if dependencies.gameSessionStore.allCardsOpened() {
            dependencies.gameSessionStore.startDiscussion()
            dependencies.router.navigate(to: .discussion)
        }
    }
}
