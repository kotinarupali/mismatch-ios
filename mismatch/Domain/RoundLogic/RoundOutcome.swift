import Foundation

enum RoundOutcome: String, Codable, Sendable {
    case insiderSideWins
    case mismatchWins
    case ghostWins

    var displayText: String {
        switch self {
        case .insiderSideWins: "Insider side wins"
        case .mismatchWins: "Mismatch wins"
        case .ghostWins: "Ghost wins"
        }
    }
}
