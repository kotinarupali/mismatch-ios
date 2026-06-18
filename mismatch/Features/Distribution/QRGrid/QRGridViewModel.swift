import Foundation
import UIKit

@MainActor
@Observable
final class QRGridViewModel {
    struct PlayerRow: Identifiable {
        let id: UUID
        let displayName: String
        let cardURL: String?
        let qrImage: UIImage?
    }

    let dependencies: AppDependencies

    private(set) var playerRows: [PlayerRow] = []
    private(set) var serverFailed = false
    private(set) var statusMessage = "Scan a QR code to open your role card."

    var hostIsPlaying: Bool {
        dependencies.gameSessionStore.currentSession?.settings.hostIsPlaying ?? false
    }

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        buildRows()
    }

    func copyLink(for playerId: UUID) {
        guard let row = playerRows.first(where: { $0.id == playerId }),
              let url = row.cardURL else { return }
        UIPasteboard.general.string = url
    }

    func startDiscussionTapped() {
        if hostIsPlaying {
            let host = dependencies.gameSessionStore.currentSession?.players.first(where: \.isHost)
            if host?.hasOpenedCard == false {
                // Host should open My Card first — still allow start for M7 simplicity
            }
        }
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

    private func buildRows() {
        guard let session = dependencies.gameSessionStore.currentSession else { return }

        if dependencies.localNetworkCardServer.baseURL == nil {
            serverFailed = true
            return
        }

        playerRows = session.players
            .filter { !$0.isHost }
            .map { player in
                let url = player.cardURL
                let image = url.flatMap { QRCodeGenerator.image(from: $0) }
                return PlayerRow(
                    id: player.id,
                    displayName: player.displayName,
                    cardURL: url,
                    qrImage: image
                )
            }

        statusMessage = "\(playerRows.count) QR codes ready on local Wi-Fi."
    }
}
