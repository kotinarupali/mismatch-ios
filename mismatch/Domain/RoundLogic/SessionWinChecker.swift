import Foundation

enum SessionWinChecker {
    /// Returns a session winner when the game should end after eliminations, or nil to continue.
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

        return outsidersWinWhenOneInsiderRemains(
            settings: settings,
            mismatchWasInGame: mismatchWasInGame,
            ghostWasInGame: ghostWasInGame,
            activeInsiders: activeInsiders,
            activeMismatches: activeMismatches,
            activeGhosts: activeGhosts
        )
    }

    /// Outcome when the host ends on no consensus — outsiders tie/outnumber insiders, or only two remain.
    static func checkNoConsensusWinner(players: [PlayerSlot], settings: GameSettings) -> RoundOutcome? {
        let active = players.filter { !$0.isEliminated }
        let activeRoles = active.compactMap { $0.assignment?.role }

        let activeInsiders = activeRoles.filter { $0 == .insider }.count
        let activeMismatches = activeRoles.filter { $0 == .mismatch }.count
        let activeGhosts = activeRoles.filter { $0 == .ghost }.count
        let activeOutsiders = activeMismatches + activeGhosts

        let ghostWasInGame = players.contains { $0.assignment?.role == .ghost }
        let mismatchWasInGame = players.contains { $0.assignment?.role == .mismatch }

        guard activeInsiders > 0, activeOutsiders > 0 else { return nil }
        guard activeOutsiders >= activeInsiders || active.count == 2 else { return nil }

        return outsidersWinWhenOneInsiderRemains(
            settings: settings,
            mismatchWasInGame: mismatchWasInGame,
            ghostWasInGame: ghostWasInGame,
            activeInsiders: activeInsiders,
            activeMismatches: activeMismatches,
            activeGhosts: activeGhosts
        ) ?? resolveOutsiderWinOutcome(
            settings: settings,
            mismatchWasInGame: mismatchWasInGame,
            ghostWasInGame: ghostWasInGame,
            activeMismatches: activeMismatches,
            activeGhosts: activeGhosts
        )
    }

    /// Infiltrators win automatically when exactly one Insider remains and at least one outsider is still in.
    private static func outsidersWinWhenOneInsiderRemains(
        settings: GameSettings,
        mismatchWasInGame: Bool,
        ghostWasInGame: Bool,
        activeInsiders: Int,
        activeMismatches: Int,
        activeGhosts: Int
    ) -> RoundOutcome? {
        guard activeInsiders == 1, activeMismatches + activeGhosts >= 1 else { return nil }
        return resolveOutsiderWinOutcome(
            settings: settings,
            mismatchWasInGame: mismatchWasInGame,
            ghostWasInGame: ghostWasInGame,
            activeMismatches: activeMismatches,
            activeGhosts: activeGhosts
        )
    }

    private static func resolveOutsiderWinOutcome(
        settings: GameSettings,
        mismatchWasInGame: Bool,
        ghostWasInGame: Bool,
        activeMismatches: Int,
        activeGhosts: Int
    ) -> RoundOutcome? {
        if settings.mismatchGhostAlliance {
            if mismatchWasInGame || ghostWasInGame {
                return .outsiderSideWins
            }
        } else if activeMismatches > 0 && activeGhosts > 0 {
            return .outsiderSideWins
        } else if activeMismatches > 0 {
            return .mismatchWins
        } else if activeGhosts > 0 {
            return .ghostWins
        }
        return nil
    }
}
