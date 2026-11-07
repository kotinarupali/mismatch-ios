import Foundation

enum RemoteCardSessionError: Error {
    case notConfigured
    case invalidResponse
    case serverError(statusCode: Int)
}

struct RemoteCardSessionSnapshot: Decodable, Sendable {
    struct Player: Decodable, Sendable {
        let id: UUID
        let displayName: String
        let hasOpenedCard: Bool
        let nameHeld: Bool

        private enum CodingKeys: String, CodingKey {
            case id
            case displayName
            case hasOpenedCard
            case nameHeld
        }

        init(id: UUID, displayName: String, hasOpenedCard: Bool, nameHeld: Bool = false) {
            self.id = id
            self.displayName = displayName
            self.hasOpenedCard = hasOpenedCard
            self.nameHeld = nameHeld
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            displayName = try container.decode(String.self, forKey: .displayName)
            hasOpenedCard = try container.decode(Bool.self, forKey: .hasOpenedCard)
            nameHeld = try container.decodeIfPresent(Bool.self, forKey: .nameHeld) ?? false
        }
    }

    struct Assignment: Decodable, Sendable {
        let id: UUID
        let role: Role
        let word: String?
        let categoryHint: String?
    }

    struct ClaimedCard: Decodable, Sendable {
        let cardIndex: Int
        let playerId: UUID
        let playerName: String
    }

    struct VoteCast: Decodable, Sendable, Equatable {
        let voterId: UUID
        let voterName: String
        let targetId: UUID
        let targetName: String
    }

    let players: [Player]
    let claimedCards: [ClaimedCard]
    let faceDownCardCount: Int
    let showRoleOnCard: Bool
    let revision: Int
    let ended: Bool?
    let assignments: [Assignment]?
    let votingEnabled: Bool?
    let votingOpen: Bool?
    let votingRound: Int?
    let voteTallies: [String: Int]?
    let voteCasts: [VoteCast]?

    init(
        players: [Player],
        claimedCards: [ClaimedCard],
        faceDownCardCount: Int,
        showRoleOnCard: Bool,
        revision: Int,
        ended: Bool? = nil,
        assignments: [Assignment]? = nil,
        votingEnabled: Bool? = nil,
        votingOpen: Bool? = nil,
        votingRound: Int? = nil,
        voteTallies: [String: Int]? = nil,
        voteCasts: [VoteCast]? = nil
    ) {
        self.players = players
        self.claimedCards = claimedCards
        self.faceDownCardCount = faceDownCardCount
        self.showRoleOnCard = showRoleOnCard
        self.revision = revision
        self.ended = ended
        self.assignments = assignments
        self.votingEnabled = votingEnabled
        self.votingOpen = votingOpen
        self.votingRound = votingRound
        self.voteTallies = voteTallies
        self.voteCasts = voteCasts
    }

    var voteTalliesByPlayerId: [UUID: Int] {
        guard let voteTallies else { return [:] }
        var mapped: [UUID: Int] = [:]
        for (key, count) in voteTallies {
            guard let id = UUID(uuidString: key) else { continue }
            mapped[id] = count
        }
        return mapped
    }
}

enum RemoteVotingAction: String, Encodable {
    case open
    case close
    case sync
    case revote
}

@MainActor
final class RemoteCardSessionClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func isAvailable() -> Bool {
        CloudCardConfig.isConfigured
    }

    func createSession(from gameSession: GameSession, hostDisplayName: String) async throws -> SharedCardSessionStartResult {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/sessions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            makeCreatePayload(from: gameSession, hostDisplayName: hostDisplayName)
        )

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        struct CreateResponse: Decodable {
            let sessionToken: String
            let joinURL: String
            let hostKey: String?
        }

        guard let decoded = try? JSONDecoder().decode(CreateResponse.self, from: data) else {
            throw RemoteCardSessionError.invalidResponse
        }

        return SharedCardSessionStartResult(
            joinURL: decoded.joinURL,
            sessionToken: decoded.sessionToken,
            hostKey: decoded.hostKey
        )
    }

    func fetchSnapshot(token: String, hostKey: String? = nil) async throws -> RemoteCardSessionSnapshot {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/session/\(token)"),
            resolvingAgainstBaseURL: false
        )
        if let hostKey {
            components?.queryItems = [URLQueryItem(name: "hostKey", value: hostKey)]
        }
        guard let url = components?.url else {
            throw RemoteCardSessionError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let snapshot = try? JSONDecoder().decode(RemoteCardSessionSnapshot.self, from: data) else {
            throw RemoteCardSessionError.invalidResponse
        }
        if snapshot.ended == true {
            throw RemoteCardSessionError.invalidResponse
        }
        return snapshot
    }

    func controlVoting(
        token: String,
        hostKey: String,
        action: RemoteVotingAction,
        eliminatedPlayerIds: [UUID],
        revoteExcludedPlayerIds: [UUID] = []
    ) async throws {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/sessions/\(token)/voting")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            VotingControlPayload(
                hostKey: hostKey,
                action: action.rawValue,
                eliminatedPlayerIds: eliminatedPlayerIds.map(\.uuidString),
                revoteExcludedPlayerIds: revoteExcludedPlayerIds.map(\.uuidString)
            )
        )

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    func swapGhostRole(token: String, playerId: UUID, hostKey: String?) async throws {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/session/\(token)/swap-ghost")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var payload = ["playerId": playerId.uuidString]
        if let hostKey {
            payload["hostKey"] = hostKey
        }
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    func hostOpenedCard(
        token: String,
        hostKey: String,
        playerId: UUID,
        cardIndex: Int,
        role: String,
        word: String?,
        categoryHint: String?
    ) async throws {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/sessions/\(token)/host-card")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            HostCardPayload(
                hostKey: hostKey,
                playerId: playerId.uuidString,
                cardIndex: cardIndex,
                role: role,
                word: word,
                categoryHint: categoryHint
            )
        )

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    func releasePlayer(token: String, hostKey: String, playerId: UUID) async throws {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/sessions/\(token)/release")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ReleasePayload(hostKey: hostKey, playerId: playerId.uuidString)
        )

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    func invalidate(token: String, hostKey: String) async {
        guard let baseURL = CloudCardConfig.baseURL else { return }

        let url = baseURL.appendingPathComponent("api/sessions/\(token)/delete")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(DeletePayload(hostKey: hostKey))
        _ = try? await session.data(for: request)
    }

    private func makeCreatePayload(from gameSession: GameSession, hostDisplayName: String) -> CreatePayload {
        let faceDownCardCount = CardPickRules.faceDownCardCount(playerCount: gameSession.players.count)
        let players = gameSession.players.compactMap { player -> CreatePayload.Player? in
            guard let assignment = player.assignment else { return nil }
            let displayName = player.isHost ? hostDisplayName : player.displayName
            return CreatePayload.Player(
                id: player.id.uuidString,
                displayName: displayName,
                isHost: player.isHost,
                role: assignment.role.rawValue,
                word: assignment.word,
                categoryHint: assignment.categoryHint
            )
        }

        return CreatePayload(
            players: players,
            faceDownCardCount: faceDownCardCount,
            showRoleOnCard: gameSession.settings.showRoleOnCard,
            insiderWord: gameSession.currentInsiderWord,
            votingEnabled: gameSession.settings.cloudGuestVotingEnabled,
            ghostPickAgainEnabled: gameSession.settings.ghostPickAgainEnabled
        )
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw RemoteCardSessionError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw RemoteCardSessionError.serverError(statusCode: http.statusCode)
        }
    }
}

private struct CreatePayload: Encodable {
    struct Player: Encodable {
        let id: String
        let displayName: String
        let isHost: Bool
        let role: String
        let word: String?
        let categoryHint: String?
    }

    let players: [Player]
    let faceDownCardCount: Int
    let showRoleOnCard: Bool
    let insiderWord: String?
    let votingEnabled: Bool
    let ghostPickAgainEnabled: Bool
}

private struct DeletePayload: Encodable {
    let hostKey: String
}

private struct ReleasePayload: Encodable {
    let hostKey: String
    let playerId: String
}

private struct HostCardPayload: Encodable {
    let hostKey: String
    let playerId: String
    let cardIndex: Int
    let role: String
    let word: String?
    let categoryHint: String?
}

private struct VotingControlPayload: Encodable {
    let hostKey: String
    let action: String
    let eliminatedPlayerIds: [String]
    let revoteExcludedPlayerIds: [String]
}
