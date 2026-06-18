import Foundation

enum SessionWinChecker {
    /// Returns a session winner when the game should end, or nil to continue playing.
    static func checkWinner(players: [PlayerSlot], settings: GameSettings) -> RoundOutcome? {
        let active = players.filter { !$0.isEliminated }
        let activeRoles = active.compactMap { $0.assignment?.role }

        let activeInsiders = activeRoles.filter { $0 == .insider }.count
        let activeMismatches = activeRoles.filter { $0 == .mismatch }.count
        let activeGhosts = activeRoles.filter { $0 == .ghost }.count

        let allMismatchesEliminated = players
            .filter { $0.assignment?.role == .mismatch }
            .allSatisfy(\.isEliminated)
        let allGhostsEliminated = players
            .filter { $0.assignment?.role == .ghost }
            .allSatisfy(\.isEliminated)
        let allInsidersEliminated = players
            .filter { $0.assignment?.role == .insider }
            .allSatisfy(\.isEliminated)

        let ghostWasInGame = players.contains { $0.assignment?.role == .ghost }
        let mismatchWasInGame = players.contains { $0.assignment?.role == .mismatch }

        if settings.mismatchGhostAlliance {
            if mismatchWasInGame || ghostWasInGame {
                if allMismatchesEliminated && (!ghostWasInGame || allGhostsEliminated) {
                    return .insiderSideWins
                }
                if allInsidersEliminated && (activeMismatches > 0 || activeGhosts > 0) {
                    return .outsiderSideWins
                }
            }
        } else {
            if mismatchWasInGame && allMismatchesEliminated {
                if !ghostWasInGame || allGhostsEliminated {
                    return .insiderSideWins
                }
            }

            if allInsidersEliminated && activeMismatches > 0 {
                return .mismatchWins
            }

            if ghostWasInGame && allInsidersEliminated && activeMismatches == 0 && activeGhosts > 0 {
                return .ghostWins
            }
        }

        // Insiders start as the majority; once outsiders tie or outnumber them, insiders
        // can no longer vote out every outsider — end the session for the outsider side.
        if activeInsiders > 0 {
            let activeOutsiders = activeMismatches + activeGhosts
            if activeOutsiders > 0 && activeOutsiders >= activeInsiders {
                if settings.mismatchGhostAlliance {
                    return .outsiderSideWins
                }
                if activeMismatches > 0 {
                    return .mismatchWins
                }
                return .ghostWins
            }
        }

        guard active.count >= 2 else { return nil }

        return nil
    }
}
