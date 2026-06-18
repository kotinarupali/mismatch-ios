import Foundation

enum ScoringEngine {
    /// +1 for each player who survives the round. +6 if the eliminated Ghost guessed correctly.
    static func computeRoundScores(
        players: [PlayerSlot],
        eliminatedPlayerId: UUID,
        ghostGuessCorrect: Bool?
    ) -> [ScoreEvent] {
        var events: [ScoreEvent] = []

        for player in players {
            if player.id == eliminatedPlayerId {
                if player.assignment?.role == .ghost, ghostGuessCorrect == true {
                    events.append(ScoreEvent(playerId: player.id, reason: .ghostCorrectGuess))
                }
                continue
            }

            guard !player.isEliminated else { continue }
            events.append(ScoreEvent(playerId: player.id, reason: .survived))
        }

        return events
    }

    /// +3 for surviving players on the winning side when the session ends.
    static func computeSessionWinBonuses(
        players: [PlayerSlot],
        outcome: RoundOutcome,
        settings: GameSettings
    ) -> [ScoreEvent] {
        var events: [ScoreEvent] = []

        for player in players where !player.isEliminated {
            guard let role = player.assignment?.role else { continue }

            switch outcome {
            case .insiderSideWins:
                if role == .insider {
                    events.append(ScoreEvent(playerId: player.id, reason: .insiderWinBonus))
                }
            case .mismatchWins:
                if role == .mismatch {
                    events.append(ScoreEvent(playerId: player.id, reason: .mismatchWinBonus))
                }
            case .ghostWins:
                if role == .ghost {
                    events.append(ScoreEvent(playerId: player.id, reason: .ghostWinBonus))
                }
            case .outsiderSideWins:
                switch role {
                case .mismatch:
                    events.append(ScoreEvent(playerId: player.id, reason: .mismatchWinBonus))
                case .ghost:
                    events.append(ScoreEvent(playerId: player.id, reason: .ghostWinBonus))
                case .insider:
                    break
                }
            }
        }

        return events
    }

    static func totalPoints(for events: [ScoreEvent]) -> Int {
        events.reduce(0) { $0 + $1.points }
    }

    static func pointsByPlayer(from events: [ScoreEvent]) -> [UUID: Int] {
        var totals: [UUID: Int] = [:]
        for event in events {
            totals[event.playerId, default: 0] += event.points
        }
        return totals
    }

    static func sampleScoreboard() -> [SessionScoreRow] {
        [
            SessionScoreRow(
                id: UUID(),
                displayName: "Alex",
                avatarColor: .green,
                sessionScore: 8,
                roundPoints: 1,
                isHost: false,
                rank: 1
            ),
            SessionScoreRow(
                id: UUID(),
                displayName: "You",
                avatarColor: .blue,
                sessionScore: 7,
                roundPoints: 1,
                isHost: true,
                rank: 2
            ),
            SessionScoreRow(
                id: UUID(),
                displayName: "Jordan",
                avatarColor: .orange,
                sessionScore: 4,
                roundPoints: 0,
                isHost: false,
                rank: 3
            ),
            SessionScoreRow(
                id: UUID(),
                displayName: "Sam",
                avatarColor: .red,
                sessionScore: 0,
                roundPoints: 0,
                isHost: false,
                rank: 4
            )
        ]
    }

    static func sampleRoundEvents() -> [ScoreEvent] {
        let alex = UUID()
        let host = UUID()
        return [
            ScoreEvent(playerId: alex, reason: .survived),
            ScoreEvent(playerId: host, reason: .survived)
        ]
    }

    static func sampleWinBonusEvents() -> [ScoreEvent] {
        let alex = UUID()
        let host = UUID()
        return [
            ScoreEvent(playerId: host, reason: .insiderWinBonus),
            ScoreEvent(playerId: alex, reason: .insiderWinBonus)
        ]
    }
}
