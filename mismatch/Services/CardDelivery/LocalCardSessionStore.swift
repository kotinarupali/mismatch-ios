import Foundation

struct LocalCardAssignment: Sendable {
    let playerSlotId: UUID
    let role: Role
    let word: String?
    let categoryHint: String?
}

enum LocalCardClaimError: Error, Equatable {
    case unknownSession
    case unknownPlayer
    case cardTaken
    case alreadyClaimed
    case hostMustUseApp
}

struct LocalCardSessionSnapshot: Sendable {
    struct Player: Sendable {
        let id: UUID
        let displayName: String
        let hasOpenedCard: Bool
    }

    struct ClaimedCard: Sendable {
        let cardIndex: Int
        let playerName: String
    }

    let players: [Player]
    let claimedCards: [ClaimedCard]
    let faceDownCardCount: Int
    let showRoleOnCard: Bool
}

@MainActor
final class LocalCardSessionStore {
    private(set) var sessionToken: String?
    private var assignments: [UUID: LocalCardAssignment] = [:]
    private var claimedIndices: [Int: UUID] = [:]
    private var openedPlayerIds: Set<UUID> = []
    private var playerNames: [UUID: String] = [:]
    private var hostPlayerIds: Set<UUID> = []

    private(set) var faceDownCardCount = 4
    private(set) var showRoleOnCard = false
    private(set) var insiderWord: String?

    var onClaim: ((UUID, Int) -> Void)?

    func configure(with session: GameSession) {
        clear()
        sessionToken = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        faceDownCardCount = CardPickRules.faceDownCardCount(playerCount: session.players.count)
        showRoleOnCard = session.settings.showRoleOnCard
        insiderWord = session.currentInsiderWord

        for player in session.players where player.assignment != nil {
            guard let assignment = player.assignment else { continue }
            let name = player.isHost ? "Host" : player.displayName
            playerNames[player.id] = name
            if player.isHost {
                hostPlayerIds.insert(player.id)
            }
            assignments[player.id] = LocalCardAssignment(
                playerSlotId: player.id,
                role: assignment.role,
                word: assignment.word,
                categoryHint: assignment.categoryHint
            )
        }
    }

    func snapshot() -> LocalCardSessionSnapshot? {
        guard sessionToken != nil else { return nil }

        let players = assignments.keys.sorted { lhs, rhs in
            (playerNames[lhs] ?? "") < (playerNames[rhs] ?? "")
        }.compactMap { playerId -> LocalCardSessionSnapshot.Player? in
            guard !hostPlayerIds.contains(playerId) else { return nil }
            return LocalCardSessionSnapshot.Player(
                id: playerId,
                displayName: playerNames[playerId] ?? "Player",
                hasOpenedCard: openedPlayerIds.contains(playerId)
            )
        }

        let claimedCards = claimedIndices.sorted { $0.key < $1.key }.map { index, playerId in
            LocalCardSessionSnapshot.ClaimedCard(
                cardIndex: index,
                playerName: playerNames[playerId] ?? "Player"
            )
        }

        return LocalCardSessionSnapshot(
            players: players,
            claimedCards: claimedCards,
            faceDownCardCount: faceDownCardCount,
            showRoleOnCard: showRoleOnCard
        )
    }

    func claimCard(playerId: UUID, cardIndex: Int) -> Result<LocalCardAssignment, LocalCardClaimError> {
        guard sessionToken != nil else { return .failure(.unknownSession) }
        guard assignments[playerId] != nil else { return .failure(.unknownPlayer) }
        guard !hostPlayerIds.contains(playerId) else { return .failure(.hostMustUseApp) }
        guard !openedPlayerIds.contains(playerId) else { return .failure(.alreadyClaimed) }
        guard cardIndex >= 0, cardIndex < faceDownCardCount else { return .failure(.cardTaken) }
        guard claimedIndices[cardIndex] == nil else { return .failure(.cardTaken) }
        guard let assignment = assignments[playerId] else { return .failure(.unknownPlayer) }

        claimedIndices[cardIndex] = playerId
        openedPlayerIds.insert(playerId)
        onClaim?(playerId, cardIndex)
        return .success(assignment)
    }

    func clear() {
        sessionToken = nil
        assignments.removeAll()
        claimedIndices.removeAll()
        openedPlayerIds.removeAll()
        playerNames.removeAll()
        hostPlayerIds.removeAll()
        insiderWord = nil
        onClaim = nil
    }
}
