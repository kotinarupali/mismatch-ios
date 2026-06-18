import Foundation

struct GameSettings: Codable, Equatable, Sendable {
    var hostIsPlaying: Bool
    var ghostEnabled: Bool
    var showRoleOnCard: Bool
    var ghostMode: GhostMode
    var mismatchGhostAlliance: Bool
    var timerSeconds: Int
    var discussionTimerEnabled: Bool
    var wordPackId: String
    var distributionMode: DistributionMode

    static let `default` = GameSettings(
        hostIsPlaying: true,
        ghostEnabled: false,
        showRoleOnCard: false,
        ghostMode: .classic,
        mismatchGhostAlliance: false,
        timerSeconds: 180,
        discussionTimerEnabled: false,
        wordPackId: "general",
        distributionMode: .passThePhone
    )
}
