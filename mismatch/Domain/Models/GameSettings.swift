import Foundation

struct GameSettings: Codable, Equatable, Sendable {
    var hostIsPlaying: Bool
    var ghostEnabled: Bool
    var ghostPickAgainEnabled: Bool
    var showRoleOnCard: Bool
    var ghostMode: GhostMode
    var mismatchGhostAlliance: Bool
    var timerSeconds: Int
    var discussionTimerEnabled: Bool
    var wordPackId: String
    var distributionMode: DistributionMode
    /// When true with Cloud QR, guests can cast elimination votes on their web card.
    var cloudGuestVotingEnabled: Bool

    static let `default` = GameSettings(
        hostIsPlaying: true,
        ghostEnabled: false,
        ghostPickAgainEnabled: true,
        showRoleOnCard: false,
        ghostMode: .classic,
        mismatchGhostAlliance: false,
        timerSeconds: 180,
        discussionTimerEnabled: false,
        wordPackId: "general",
        distributionMode: .passThePhone,
        cloudGuestVotingEnabled: false
    )
}
