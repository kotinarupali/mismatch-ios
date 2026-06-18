import Foundation

struct LocalCardToken: Sendable {
    let token: String
    let playerSlotId: UUID
    let role: Role
    let word: String?
    let categoryHint: String?
    let showRoleOnCard: Bool
}

@MainActor
final class LocalCardTokenStore {
    private var tokensById: [String: LocalCardToken] = [:]
    private var tokenByPlayerId: [UUID: String] = [:]

    func register(_ token: LocalCardToken) {
        tokensById[token.token] = token
        tokenByPlayerId[token.playerSlotId] = token.token
    }

    func token(for id: String) -> LocalCardToken? {
        tokensById[id]
    }

    func tokenString(forPlayer playerId: UUID) -> String? {
        tokenByPlayerId[playerId]
    }

    func clear() {
        tokensById.removeAll()
        tokenByPlayerId.removeAll()
    }
}
