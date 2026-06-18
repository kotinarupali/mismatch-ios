import Foundation

enum ScoreReason: String, Codable, Sendable, CaseIterable {
    case survived
    case insiderWinBonus
    case mismatchWinBonus
    case ghostWinBonus
    case ghostCorrectGuess

    var points: Int {
        switch self {
        case .survived: 1
        case .insiderWinBonus, .mismatchWinBonus, .ghostWinBonus: 3
        case .ghostCorrectGuess: 6
        }
    }

    var label: String {
        switch self {
        case .survived: "Survived round"
        case .insiderWinBonus: "Insider win bonus"
        case .mismatchWinBonus: "Mismatch win bonus"
        case .ghostWinBonus: "Ghost win bonus"
        case .ghostCorrectGuess: "Correct ghost guess"
        }
    }
}
