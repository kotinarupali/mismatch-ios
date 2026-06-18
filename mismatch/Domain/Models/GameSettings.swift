import Foundation

struct GameSettings: Codable, Equatable, Sendable {
    var hostIsPlaying: Bool
    var ghostEnabled: Bool
    var showRoleOnCard: Bool
    var ghostMode: GhostMode
    var timerSeconds: Int
    var wordPackId: String
    var distributionMode: DistributionMode

    static let `default` = GameSettings(
        hostIsPlaying: true,
        ghostEnabled: false,
        showRoleOnCard: false,
        ghostMode: .classic,
        timerSeconds: 180,
        wordPackId: "general",
        distributionMode: .passThePhone
    )
}
