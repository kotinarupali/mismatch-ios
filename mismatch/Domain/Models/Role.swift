import Foundation

enum Role: String, Codable, CaseIterable, Sendable {
    case insider
    case mismatch
    case ghost

    var displayName: String {
        switch self {
        case .insider: "Insider"
        case .mismatch: "Mismatch"
        case .ghost: "Ghost"
        }
    }
}
