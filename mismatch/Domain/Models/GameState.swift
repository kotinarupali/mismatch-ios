import Foundation

enum GameState: String, Codable, Sendable {
    case lobby
    case distributing
    case discussing
    case voting
    case revealing
    case ended
}
