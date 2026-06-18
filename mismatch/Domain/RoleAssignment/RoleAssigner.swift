import Foundation

enum RoleAssignerError: Error {
    case noPlayers
    case invalidPlayerCount
}

enum GameSessionStoreError: Error {
    case noActiveSession
}

struct RoleAssigner: Sendable {
    func assign(
        players: [PlayerSlot],
        wordPair: WordPair,
        settings: GameSettings
    ) throws -> [PlayerSlot] {
        guard !players.isEmpty else { throw RoleAssignerError.noPlayers }

        let counts = RoleDistributionTable.counts(
            playerCount: players.count,
            ghostEnabled: settings.ghostEnabled
        )
        guard counts.total == players.count else {
            throw RoleAssignerError.invalidPlayerCount
        }

        var roles: [Role] = []
        roles.append(contentsOf: Array(repeating: .insider, count: counts.insider))
        roles.append(contentsOf: Array(repeating: .mismatch, count: counts.mismatch))
        roles.append(contentsOf: Array(repeating: .ghost, count: counts.ghost))

        let shuffledRoles = try CryptoRandom.shuffled(roles)

        return zip(players, shuffledRoles).map { player, role in
            var updated = player
            updated.assignment = assignment(for: role, wordPair: wordPair, settings: settings)
            updated.hasOpenedCard = false
            updated.isEliminated = false
            return updated
        }
    }

    private func assignment(for role: Role, wordPair: WordPair, settings: GameSettings) -> RoleAssignment {
        switch role {
        case .insider:
            return RoleAssignment(role: .insider, word: wordPair.insiderWord, categoryHint: nil)
        case .mismatch:
            return RoleAssignment(role: .mismatch, word: wordPair.mismatchWord, categoryHint: nil)
        case .ghost:
            let hint = settings.ghostMode == .categoryHint ? wordPair.category : nil
            return RoleAssignment(role: .ghost, word: nil, categoryHint: hint)
        }
    }
}
