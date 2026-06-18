import Foundation

enum RoundOutcome: String, Codable, Sendable {
    case insiderSideWins
    case mismatchWins
    case ghostWins
    case outsiderSideWins

    func displayText(allianceEnabled: Bool = false) -> String {
        switch self {
        case .insiderSideWins: "Insider side wins"
        case .mismatchWins:
            allianceEnabled ? "Mismatch & Ghost win" : "Mismatch wins"
        case .ghostWins:
            allianceEnabled ? "Mismatch & Ghost win" : "Ghost wins"
        case .outsiderSideWins: allianceEnabled ? "Mismatch & Ghost win" : "Outsiders win"
        }
    }

    func celebrationHeadline(allianceEnabled: Bool = false) -> String {
        switch self {
        case .insiderSideWins: "Insiders win!"
        case .mismatchWins:
            allianceEnabled ? "Mismatch & Ghost win!" : "Mismatch wins!"
        case .ghostWins:
            allianceEnabled ? "Mismatch & Ghost win!" : "Ghost wins!"
        case .outsiderSideWins: allianceEnabled ? "Mismatch & Ghost win!" : "Outsiders win!"
        }
    }

    func winningRoles(allianceEnabled: Bool = false) -> Set<Role> {
        switch self {
        case .insiderSideWins: [.insider]
        case .mismatchWins: allianceEnabled ? [.mismatch, .ghost] : [.mismatch]
        case .ghostWins: allianceEnabled ? [.mismatch, .ghost] : [.ghost]
        case .outsiderSideWins: [.mismatch, .ghost]
        }
    }
}
