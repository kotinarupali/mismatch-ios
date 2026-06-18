import Foundation
import UIKit

@MainActor
@Observable
final class QRGridViewModel {
    let dependencies: AppDependencies

    private(set) var serverFailed = false
    var showPlayerRolePicker = false
    var playerToReveal: PlayerSlot?

    private var pollTask: Task<Void, Never>?
    private var lastRevision: Int?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        serverFailed = Self.computeServerFailed(dependencies: dependencies)
        startCloudSyncIfNeeded()
    }

    deinit {
        pollTask?.cancel()
    }

    var isCloudMode: Bool {
        dependencies.gameSessionStore.currentSession?.cardDeliveryBackend == .cloud
    }

    var requirementsText: String {
        if isCloudMode {
            return "• Any internet connection (cellular or Wi‑Fi)\n• Open the link in Safari — not a QR preview pane\n• Host phone stays online until everyone has picked"
        }
        return "• Shared network: home Wi‑Fi or host Personal Hotspot (Settings → Personal Hotspot)\n• Allow Local Network on the host iPhone when prompted\n• Open the link in Safari — not a QR preview pane"
    }

    var serverFailureMessage: String {
        if isCloudMode {
            return "Could not start cloud card session. Use pass-the-phone instead."
        }
        return "Could not start local card server. Use pass-the-phone instead."
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

    var joinInstructions: String {
        if isCloudMode {
            return "Scan the QR or tap Send Link. Open in Safari — not a camera preview pane."
        }
        return "If scanning shows a blank page, tap Copy Link and paste it into Safari. Camera previews often fail for local links."
    }

    func openJoinLinkInSafari() {
        guard let urlString = sharedJoinURL, let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }

    func copySharedLink() {
        guard let url = sharedJoinURL else { return }
        UIPasteboard.general.string = url
    }

    func startDiscussionTapped() {
        stopCloudSync()
        dependencies.gameSessionStore.startDiscussion()
        dependencies.router.navigate(to: .discussion)
    }

    func fallbackToPassThePhone() {
        stopCloudSync()
        dependencies.stopCardDelivery()
        var settings = dependencies.gameSessionStore.currentSession?.settings ?? .default
        settings.distributionMode = .passThePhone
        dependencies.gameSessionStore.updateSettings(settings)
        dependencies.router.goBack()
        dependencies.router.navigate(to: .passThePhone)
    }

    func repickRoles() {
        stopCloudSync()
        dependencies.repickRoles()
    }

    func endGame() {
        stopCloudSync()
        dependencies.endGame()
    }

    func checkPlayerRoleTapped() {
        showPlayerRolePicker = true
    }

    func selectPlayerForRoleCheck(_ player: PlayerSlot) {
        playerToReveal = player
    }

    private static func computeServerFailed(dependencies: AppDependencies) -> Bool {
        guard let session = dependencies.gameSessionStore.currentSession else { return true }
        guard session.sharedJoinURL != nil else { return true }
        if session.cardDeliveryBackend == .cloud { return false }
        return dependencies.localNetworkCardServer.baseURL == nil
    }

    private func startCloudSyncIfNeeded() {
        guard isCloudMode,
              let token = dependencies.gameSessionStore.currentSession?.joinSessionToken else { return }

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                do {
                    let snapshot = try await dependencies.remoteCardSessionClient.fetchSnapshot(token: token)
                    if lastRevision != snapshot.revision {
                        lastRevision = snapshot.revision
                        dependencies.gameSessionStore.applyRemoteCardSnapshot(snapshot)
                    }
                } catch {
                    // Keep polling — transient network blips are common outdoors.
                }
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    private func stopCloudSync() {
        pollTask?.cancel()
        pollTask = nil
    }
}
