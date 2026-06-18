import Foundation

@MainActor
@Observable
final class PassThePhoneViewModel {
    private let dependencies: AppDependencies

    private var passOrder: [PlayerSlot] = []
    private var currentIndex = 0
    private(set) var awaitingHandoff = false
    var showPlayerRolePicker = false
    var playerToReveal: PlayerSlot?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        passOrder = dependencies.gameSessionStore.passThePhoneOrder()
            .filter { $0.assignment != nil && !$0.hasOpenedCard }
        if passOrder.isEmpty {
            passOrder = dependencies.gameSessionStore.passThePhoneOrder()
                .filter { $0.assignment != nil }
            currentIndex = passOrder.count
        } else {
            awaitingHandoff = true
        }
    }

    var title: String {
        guard currentPlayer != nil else { return "All roles revealed" }
        return awaitingHandoff ? "Hand off the phone" : "Pick your card"
    }

    var subtitle: String {
        guard let player = currentPlayer else {
            return "Everyone has seen their card."
        }
        if awaitingHandoff {
            return "Only \(displayName(for: player)) should tap below."
        }
        return "\(displayName(for: player)), pick a card"
    }

    var currentPlayerId: UUID? {
        currentPlayer?.id
    }

    var currentPlayerDisplayName: String {
        guard let player = currentPlayer else { return "Player" }
        return displayName(for: player)
    }

    var currentPlayerAvatarColor: AvatarColor {
        currentPlayer?.avatarColor ?? .blue
    }

    var showRoleOnCard: Bool {
        dependencies.gameSessionStore.currentSession?.settings.showRoleOnCard ?? false
    }

    var currentAssignment: RoleAssignment? {
        currentPlayer?.assignment
    }

    var faceDownCardCount: Int {
        CardPickRules.faceDownCardCount(
            playerCount: dependencies.gameSessionStore.currentSession?.players.count ?? 3
        )
    }

    var claimedCards: [ClaimedCard] {
        dependencies.gameSessionStore.claimedCards()
    }

    var playersWithPickedCards: [PlayerSlot] {
        dependencies.gameSessionStore.playersWithPickedCards()
    }

    var nextPlayerDisplayName: String? {
        guard currentIndex + 1 < passOrder.count else { return nil }
        return displayName(for: passOrder[currentIndex + 1])
    }

    var canShowCardPick: Bool {
        currentAssignment != nil && !awaitingHandoff
    }

    private var currentPlayer: PlayerSlot? {
        guard currentIndex < passOrder.count else { return nil }
        return passOrder[currentIndex]
    }

    func readyToPickTapped() {
        awaitingHandoff = false
    }

    func cardCompleted(cardIndex: Int) {
        guard let player = currentPlayer else { return }
        dependencies.gameSessionStore.markCardOpened(playerId: player.id, cardIndex: cardIndex)
        currentIndex += 1

        if dependencies.gameSessionStore.allCardsOpened() {
            dependencies.gameSessionStore.startDiscussion()
            dependencies.router.navigate(to: .discussion)
            return
        }

        awaitingHandoff = true
    }

    func repickRoles() {
        dependencies.repickRoles()
    }

    func endGame() {
        dependencies.endGame()
    }

    func checkPlayerRoleTapped() {
        showPlayerRolePicker = true
    }

    func selectPlayerForRoleCheck(_ player: PlayerSlot) {
        playerToReveal = player
    }

    private func displayName(for player: PlayerSlot) -> String {
        player.isHost ? "You" : player.displayName
    }
}
