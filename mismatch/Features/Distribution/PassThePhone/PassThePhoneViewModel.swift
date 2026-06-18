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
        reloadPassState()
    }

    var title: String {
        if isMissingRoleAssignments {
            return "Roles not ready"
        }
        guard currentPlayer != nil else { return "All roles revealed" }
        return awaitingHandoff ? "Hand off the phone" : "Pick your card"
    }

    var subtitle: String {
        if isMissingRoleAssignments {
            return "Go back to the lobby and tap Distribute Roles again."
        }
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

    var insiderWord: String? {
        dependencies.gameSessionStore.insiderWord
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

    var isMissingRoleAssignments: Bool {
        guard let session = dependencies.gameSessionStore.currentSession else { return true }
        guard !allCardsOpened else { return false }
        return !session.players.contains { $0.assignment != nil }
    }

    private var allCardsOpened: Bool {
        dependencies.gameSessionStore.allCardsOpened()
    }

    private var currentPlayer: PlayerSlot? {
        guard currentIndex < passOrder.count else { return nil }
        return passOrder[currentIndex]
    }

    func onAppear() {
        if passOrder.isEmpty && !allCardsOpened {
            reloadPassState()
        }
    }

    func readyToPickTapped() {
        awaitingHandoff = false
    }

    func cardCompleted(cardIndex: Int) {
        guard let player = currentPlayer else { return }
        dependencies.gameSessionStore.markCardOpened(playerId: player.id, cardIndex: cardIndex)
        reloadPassState()

        if allCardsOpened {
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

    func returnToLobby() {
        dependencies.repickRoles()
    }

    func checkPlayerRoleTapped() {
        showPlayerRolePicker = true
    }

    func selectPlayerForRoleCheck(_ player: PlayerSlot) {
        playerToReveal = player
    }

    private func reloadPassState() {
        let store = dependencies.gameSessionStore
        guard store.currentSession != nil else {
            passOrder = []
            currentIndex = 0
            awaitingHandoff = false
            return
        }

        let orderedPlayers = store.passThePhoneOrder()
        var remaining = orderedPlayers.filter { $0.assignment != nil && !$0.hasOpenedCard }

        if remaining.isEmpty {
            remaining = (store.currentSession?.players ?? []).filter {
                $0.assignment != nil && !$0.hasOpenedCard
            }
        }

        passOrder = remaining
        currentIndex = 0
        awaitingHandoff = !remaining.isEmpty
    }

    private func displayName(for player: PlayerSlot) -> String {
        player.isHost ? "You" : player.displayName
    }
}
