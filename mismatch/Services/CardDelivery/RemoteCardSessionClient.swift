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
    }

    struct ClaimedCard: Decodable, Sendable {
        let cardIndex: Int
        let playerId: UUID
        let playerName: String
    }

    let players: [Player]
    let claimedCards: [ClaimedCard]
    let faceDownCardCount: Int
    let showRoleOnCard: Bool
    let revision: Int
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

    func createSession(from gameSession: GameSession) async throws -> SharedCardSessionStartResult {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/sessions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(makeCreatePayload(from: gameSession))

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        struct CreateResponse: Decodable {
            let sessionToken: String
            let joinURL: String
        }

        guard let decoded = try? JSONDecoder().decode(CreateResponse.self, from: data) else {
            throw RemoteCardSessionError.invalidResponse
        }

        return SharedCardSessionStartResult(
            joinURL: decoded.joinURL,
            sessionToken: decoded.sessionToken
        )
    }

    func fetchSnapshot(token: String) async throws -> RemoteCardSessionSnapshot {
        guard let baseURL = CloudCardConfig.baseURL else {
            throw RemoteCardSessionError.notConfigured
        }

        let url = baseURL.appendingPathComponent("api/session/\(token)")
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        guard let snapshot = try? JSONDecoder().decode(RemoteCardSessionSnapshot.self, from: data) else {
            throw RemoteCardSessionError.invalidResponse
        }
        return snapshot
    }

    func invalidate(token: String) async {
        guard let baseURL = CloudCardConfig.baseURL else { return }

        let url = baseURL.appendingPathComponent("api/sessions/\(token)/delete")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        _ = try? await session.data(for: request)
    }

    private func makeCreatePayload(from gameSession: GameSession) -> CreatePayload {
        let faceDownCardCount = CardPickRules.faceDownCardCount(playerCount: gameSession.players.count)
        let players = gameSession.players.compactMap { player -> CreatePayload.Player? in
            guard let assignment = player.assignment else { return nil }
            return CreatePayload.Player(
                id: player.id.uuidString,
                displayName: player.isHost ? "Host" : player.displayName,
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
            insiderWord: gameSession.currentInsiderWord
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
}
