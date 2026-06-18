import Foundation

enum PersonaEngine {
    static func buildCards(from session: GameSession) -> [PlayerPersonaCard] {
        let stats = playerStats(from: session)
        guard !stats.isEmpty else { return [] }

        var assigned = Set<UUID>()
        var cards: [UUID: PlayerPersonaCard] = [:]

        func assign(_ persona: PersonaTemplate, to playerId: UUID, subtitle: String) {
            guard !assigned.contains(playerId), let stat = stats.first(where: { $0.playerId == playerId }) else { return }
            assigned.insert(playerId)
            cards[playerId] = makeCard(from: stat, template: persona, subtitle: subtitle)
        }

        let scoreEvents = allScoreEvents(in: session)

        for stat in stats where scoreEvents.contains(where: { $0.playerId == stat.playerId && $0.reason == .ghostCorrectGuess }) {
            assign(.graveRobber, to: stat.playerId, subtitle: "Snatched +6 with a perfect ghost guess.")
        }

        if let leader = stats.filter({ $0.sessionScore > 0 }).max(by: { $0.sessionScore < $1.sessionScore }),
           stats.filter({ $0.sessionScore == leader.sessionScore }).count == 1 {
            assign(
                .partyLegend,
                to: leader.playerId,
                subtitle: "Top score tonight with \(leader.sessionScore) points."
            )
        }

        if let survivor = stats.max(by: { $0.roundsSurvived < $1.roundsSurvived }),
           survivor.roundsSurvived >= 2,
           stats.filter({ $0.roundsSurvived == survivor.roundsSurvived }).count == 1 {
            assign(
                .smoothOperator,
                to: survivor.playerId,
                subtitle: "Survived \(survivor.roundsSurvived) round\(survivor.roundsSurvived == 1 ? "" : "s") like a pro."
            )
        }

        if let firstOut = firstEliminatedPlayerId(in: session),
           stats.contains(where: { $0.playerId == firstOut }) {
            assign(.earlyExit, to: firstOut, subtitle: "First to leave the circle tonight.")
        }

        for stat in stats where !assigned.contains(stat.playerId) {
            if stat.hasWinBonus, let role = stat.role {
                let template: PersonaTemplate = switch role {
                case .insider: .insiderMVP
                case .mismatch: .chaosCaptain
                case .ghost: .spookyStar
                }
                assign(template, to: stat.playerId, subtitle: "On the winning side when the game ended.")
            }
        }

        for stat in stats where !assigned.contains(stat.playerId) {
            if stat.sessionScore == 0 {
                assign(.wallflower, to: stat.playerId, subtitle: "Zero points, maximum vibes.")
            } else if stat.roundsSurvived >= 2 {
                assign(
                    .luckyCharm,
                    to: stat.playerId,
                    subtitle: "\(stat.sessionScore) points and \(stat.roundsSurvived) rounds in the clear."
                )
            } else if stat.isHost {
                assign(.hostWithHeart, to: stat.playerId, subtitle: "Kept the party running all night.")
            } else if let role = stat.role {
                let template: PersonaTemplate = switch role {
                case .insider: .wordKeeper
                case .mismatch: .chaosAgent
                case .ghost: .mysteryGuest
                }
                assign(template, to: stat.playerId, subtitle: rolePersonaSubtitle(for: stat, role: role))
            }
        }

        for stat in stats where !assigned.contains(stat.playerId) {
            cards[stat.playerId] = makeCard(
                from: stat,
                template: .partyGuest,
                subtitle: "\(stat.sessionScore) point\(stat.sessionScore == 1 ? "" : "s") on the board."
            )
        }

        return session.players.compactMap { cards[$0.id] }
    }

    private static func playerStats(from session: GameSession) -> [PlayerSessionStats] {
        let scoreEvents = allScoreEvents(in: session)
        let surviveCounts = Dictionary(
            grouping: scoreEvents.filter { $0.reason == .survived },
            by: \.playerId
        ).mapValues(\.count)
        let winBonusReasons: Set<ScoreReason> = [.insiderWinBonus, .mismatchWinBonus, .ghostWinBonus]
        let winBonusPlayers = Set(scoreEvents.filter { winBonusReasons.contains($0.reason) }.map(\.playerId))
        let ghostGuessPlayers = Set(scoreEvents.filter { $0.reason == .ghostCorrectGuess }.map(\.playerId))
        let eliminationRound = eliminationRoundByPlayer(in: session)

        return session.players.map { player in
            PlayerSessionStats(
                playerId: player.id,
                displayName: player.isHost ? "You" : player.displayName,
                avatarColor: player.avatarColor,
                role: player.assignment?.role,
                sessionScore: player.sessionScore,
                roundsSurvived: surviveCounts[player.id] ?? 0,
                hasWinBonus: winBonusPlayers.contains(player.id),
                hasGhostGuess: ghostGuessPlayers.contains(player.id),
                eliminationRoundIndex: eliminationRound[player.id],
                isHost: player.isHost
            )
        }
    }

    private static func allScoreEvents(in session: GameSession) -> [ScoreEvent] {
        session.rounds.flatMap(\.scoreEvents) + session.sessionEndScoreEvents
    }

    private static func eliminationRoundByPlayer(in session: GameSession) -> [UUID: Int] {
        var lookup: [UUID: Int] = [:]
        for round in session.rounds {
            guard let playerId = round.eliminatedPlayerId else { continue }
            if lookup[playerId] == nil {
                lookup[playerId] = round.index
            }
        }
        return lookup
    }

    private static func firstEliminatedPlayerId(in session: GameSession) -> UUID? {
        session.rounds
            .sorted { $0.index < $1.index }
            .compactMap(\.eliminatedPlayerId)
            .first
    }

    private static func rolePersonaSubtitle(for stat: PlayerSessionStats, role: Role) -> String {
        switch role {
        case .insider:
            "Kept the secret word safe for \(stat.sessionScore) point\(stat.sessionScore == 1 ? "" : "s")."
        case .mismatch:
            "Spread just enough chaos to earn \(stat.sessionScore) point\(stat.sessionScore == 1 ? "" : "s")."
        case .ghost:
            "Lurked, bluffed, and finished with \(stat.sessionScore) point\(stat.sessionScore == 1 ? "" : "s")."
        }
    }

    private static func makeCard(
        from stat: PlayerSessionStats,
        template: PersonaTemplate,
        subtitle: String
    ) -> PlayerPersonaCard {
        PlayerPersonaCard(
            id: stat.playerId,
            displayName: stat.displayName,
            avatarColor: stat.avatarColor,
            title: template.title,
            subtitle: subtitle,
            symbolName: template.symbolName,
            accentHex: template.accent
        )
    }

    private enum PersonaTemplate {
        case partyLegend
        case smoothOperator
        case graveRobber
        case earlyExit
        case insiderMVP
        case chaosCaptain
        case spookyStar
        case wallflower
        case luckyCharm
        case hostWithHeart
        case wordKeeper
        case chaosAgent
        case mysteryGuest
        case partyGuest

        var title: String {
            switch self {
            case .partyLegend: "Party Legend"
            case .smoothOperator: "Smooth Operator"
            case .graveRobber: "Grave Robber"
            case .earlyExit: "Early Exit"
            case .insiderMVP: "Insider MVP"
            case .chaosCaptain: "Chaos Captain"
            case .spookyStar: "Spooky Star"
            case .wallflower: "Wallflower"
            case .luckyCharm: "Lucky Charm"
            case .hostWithHeart: "Host with Heart"
            case .wordKeeper: "Word Keeper"
            case .chaosAgent: "Chaos Agent"
            case .mysteryGuest: "Mystery Guest"
            case .partyGuest: "Party Guest"
            }
        }

        var symbolName: String {
            switch self {
            case .partyLegend: "crown.fill"
            case .smoothOperator: "shield.lefthalf.filled"
            case .graveRobber: "wand.and.stars"
            case .earlyExit: "figure.walk.departure"
            case .insiderMVP: "checkmark.seal.fill"
            case .chaosCaptain: "bolt.fill"
            case .spookyStar: "moon.stars.fill"
            case .wallflower: "camera.macro"
            case .luckyCharm: "leaf.fill"
            case .hostWithHeart: "heart.circle.fill"
            case .wordKeeper: "eye.fill"
            case .chaosAgent: "questionmark.diamond.fill"
            case .mysteryGuest: "cloud.fill"
            case .partyGuest: "sparkles"
            }
        }

        var accent: PersonaAccent {
            switch self {
            case .partyLegend: .gold
            case .smoothOperator: .mint
            case .graveRobber: .violet
            case .earlyExit: .coral
            case .insiderMVP: .mint
            case .chaosCaptain: .coral
            case .spookyStar: .violet
            case .wallflower: .sky
            case .luckyCharm: .amber
            case .hostWithHeart: .rose
            case .wordKeeper: .mint
            case .chaosAgent: .coral
            case .mysteryGuest: .violet
            case .partyGuest: .sky
            }
        }
    }
}
