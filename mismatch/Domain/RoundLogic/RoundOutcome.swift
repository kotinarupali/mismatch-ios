import Foundation

enum RoundOutcome: String, Codable, Sendable {
    case insiderSideWins
    case mismatchWins
    case ghostWins
    case outsiderSideWins

    func displayText(allianceEnabled: Bool = false) -> String {
        switch self {
        case .insiderSideWins: "Insider side wins"
        case .mismatchWins: "Mismatch wins"
        case .ghostWins: "Ghost wins"
        case .outsiderSideWins: allianceEnabled ? "Mismatch & Ghost win" : "Outsiders win"
        }
    }
}
