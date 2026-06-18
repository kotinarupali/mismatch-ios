import Foundation

enum WinConditionEvaluator {
    /// Evaluates round outcome from the eliminated player's role.
    static func evaluate(eliminatedPlayer: PlayerSlot) -> RoundOutcome {
        guard let role = eliminatedPlayer.assignment?.role else {
            return .insiderSideWins
        }

        switch role {
        case .mismatch, .ghost:
            return .insiderSideWins
        case .insider:
            return .mismatchWins
        }
    }
}
