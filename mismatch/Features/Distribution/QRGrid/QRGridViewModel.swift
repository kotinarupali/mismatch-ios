import Foundation
import UIKit

@MainActor
@Observable
final class QRGridViewModel {
    let dependencies: AppDependencies

    private(set) var serverFailed = false
    var showPlayerRolePicker = false
    var playerToReveal: PlayerSlot?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        serverFailed = dependencies.localNetworkCardServer.baseURL == nil
            || dependencies.gameSessionStore.currentSession?.sharedJoinURL == nil
    }

    var sharedJoinURL: String? {
        dependencies.gameSessionStore.currentSession?.sharedJoinURL
    }

    var qrImage: UIImage? {
        sharedJoinURL.flatMap { QRCodeGenerator.image(from: $0) }
    }

    var statusMessage: String {
        let picked = pickedCount
        let total = totalPickCount
        if total == 0 { return "Scan to join and pick a card." }
        return "\(picked) of \(total) players have picked a card"
    }

    var guestPlayers: [PlayerSlot] {
        dependencies.gameSessionStore.currentSession?.players.filter { !$0.isHost } ?? []
    }

    var pickedCount: Int {
        guestPlayers.filter(\.hasOpenedCard).count + (hostHasPicked ? 1 : 0)
    }

    var totalPickCount: Int {
        let session = dependencies.gameSessionStore.currentSession
        let guestTotal = session?.players.filter { !$0.isHost }.count ?? 0
        let hostPlaying = session?.settings.hostIsPlaying ?? false
        return guestTotal + (hostPlaying ? 1 : 0)
    }

    var hostIsPlaying: Bool {
        dependencies.gameSessionStore.currentSession?.settings.hostIsPlaying ?? false
    }

    var hostHasPicked: Bool {
        guard hostIsPlaying else { return false }
        return dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost)?.hasOpenedCard ?? false
    }

    var canStartDiscussion: Bool {
        dependencies.gameSessionStore.allCardsOpened()
    }

    var playersWithPickedCards: [PlayerSlot] {
        dependencies.gameSessionStore.playersWithPickedCards()
    }

    func copySharedLink() {
        guard let url = sharedJoinURL else { return }
        UIPasteboard.general.string = url
    }

    func startDiscussionTapped() {
        dependencies.gameSessionStore.startDiscussion()
        dependencies.router.navigate(to: .discussion)
    }

    func fallbackToPassThePhone() {
        dependencies.localNetworkCardServer.stop()
        var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        settings.distributionMode = .passThePhone
        dependencies.gameSessionStore.updateSettings(settings)
        dependencies.router.goBack()
        dependencies.router.navigate(to: .passThePhone)
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
}
