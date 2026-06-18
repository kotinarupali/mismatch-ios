import Foundation
import SwiftData

@MainActor
final class ProfileRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() throws -> [PlayerProfile] {
        let descriptor = FetchDescriptor<PlayerProfileEntity>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map(mapProfile)
    }

    func fetch(id: UUID) throws -> PlayerProfile? {
        var descriptor = FetchDescriptor<PlayerProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map(mapProfile)
    }

    @discardableResult
    func create(name: String, avatarColor: AvatarColor) throws -> PlayerProfile {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProfileRepositoryError.invalidName
        }

        let entity = PlayerProfileEntity(
            name: trimmed,
            avatarColorRaw: avatarColor.rawValue
        )
        modelContext.insert(entity)
        try modelContext.save()
        return mapProfile(entity)
    }

    func findByName(_ name: String) throws -> PlayerProfile? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let profiles = try fetchAll()
        return profiles.first { $0.name == trimmed }
    }

    @discardableResult
    func findOrCreate(name: String, avatarColor: AvatarColor? = nil) throws -> PlayerProfile {
        if let existing = try findByName(name) {
            return existing
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProfileRepositoryError.invalidName
        }

        let color = avatarColor ?? AvatarColor.forIndex(try fetchAll().count)
        return try create(name: trimmed, avatarColor: color)
    }

    func update(id: UUID, name: String, avatarColor: AvatarColor) throws {
        guard let entity = try fetchEntity(id: id) else {
            throw ProfileRepositoryError.notFound
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ProfileRepositoryError.invalidName
        }

        entity.name = trimmed
        entity.avatarColorRaw = avatarColor.rawValue
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        guard let entity = try fetchEntity(id: id) else {
            throw ProfileRepositoryError.notFound
        }
        modelContext.delete(entity)
        try modelContext.save()
    }

    /// Applies session results to linked profiles. Call once per session summary.
    func applySessionStats(from session: GameSession, winnerPlayerIds: Set<UUID>) throws {
        let completedGames = session.gamesPlayedCount
        let hasScoringActivity = session.players.contains { $0.sessionScore > 0 }

        for player in session.players {
            var profileId = player.profileId
            if profileId == nil, !player.isHost {
                profileId = try findOrCreate(
                    name: player.displayName,
                    avatarColor: player.avatarColor
                ).id
            }
            guard let profileId else { continue }
            guard let entity = try fetchEntity(id: profileId) else { continue }

            entity.totalPoints += player.sessionScore

            if completedGames > 0 {
                entity.gamesPlayed += completedGames
            } else if hasScoringActivity, player.sessionScore > 0 {
                entity.gamesPlayed += 1
            }

            let won = winnerPlayerIds.contains(player.id)
            if won, let role = player.assignment?.role {
                switch role {
                case .insider: entity.winsAsInsider += 1
                case .mismatch: entity.winsAsMismatch += 1
                case .ghost: entity.winsAsGhost += 1
                }
                entity.currentStreak += 1
                entity.bestStreak = max(entity.bestStreak, entity.currentStreak)
            } else if completedGames > 0 || hasScoringActivity {
                entity.currentStreak = 0
            }
        }

        try modelContext.save()
    }

    private func fetchEntity(id: UUID) throws -> PlayerProfileEntity? {
        var descriptor = FetchDescriptor<PlayerProfileEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func mapProfile(_ entity: PlayerProfileEntity) -> PlayerProfile {
        PlayerProfile(
            id: entity.id,
            name: entity.name,
            avatarColor: AvatarColor(rawValue: entity.avatarColorRaw) ?? .blue,
            createdAt: entity.createdAt,
            stats: PlayerProfileStats(
                gamesPlayed: entity.gamesPlayed,
                winsAsInsider: entity.winsAsInsider,
                winsAsMismatch: entity.winsAsMismatch,
                winsAsGhost: entity.winsAsGhost,
                totalPoints: entity.totalPoints,
                currentStreak: entity.currentStreak,
                bestStreak: entity.bestStreak
            )
        )
    }
}

enum ProfileRepositoryError: Error, Equatable {
    case invalidName
    case notFound
}
