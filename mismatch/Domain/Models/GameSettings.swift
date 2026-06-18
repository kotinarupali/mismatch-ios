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
    var selectedWordPackIds: [String]
    var distributionMode: DistributionMode
    /// When true with Cloud QR, guests can cast elimination votes on their web card.
    var cloudGuestVotingEnabled: Bool

    static let defaultSelectedWordPackIds = ["general"]

    static let `default` = GameSettings(
        hostIsPlaying: true,
        ghostEnabled: false,
        ghostPickAgainEnabled: true,
        showRoleOnCard: false,
        ghostMode: .classic,
        mismatchGhostAlliance: false,
        timerSeconds: 180,
        discussionTimerEnabled: false,
        selectedWordPackIds: defaultSelectedWordPackIds,
        distributionMode: .passThePhone,
        cloudGuestVotingEnabled: false
    )

    private enum CodingKeys: String, CodingKey {
        case hostIsPlaying
        case ghostEnabled
        case ghostPickAgainEnabled
        case showRoleOnCard
        case ghostMode
        case mismatchGhostAlliance
        case timerSeconds
        case discussionTimerEnabled
        case selectedWordPackIds
        case wordPackId
        case distributionMode
        case cloudGuestVotingEnabled
    }

    init(
        hostIsPlaying: Bool,
        ghostEnabled: Bool,
        ghostPickAgainEnabled: Bool,
        showRoleOnCard: Bool,
        ghostMode: GhostMode,
        mismatchGhostAlliance: Bool,
        timerSeconds: Int,
        discussionTimerEnabled: Bool,
        selectedWordPackIds: [String],
        distributionMode: DistributionMode,
        cloudGuestVotingEnabled: Bool
    ) {
        self.hostIsPlaying = hostIsPlaying
        self.ghostEnabled = ghostEnabled
        self.ghostPickAgainEnabled = ghostPickAgainEnabled
        self.showRoleOnCard = showRoleOnCard
        self.ghostMode = ghostMode
        self.mismatchGhostAlliance = mismatchGhostAlliance
        self.timerSeconds = timerSeconds
        self.discussionTimerEnabled = discussionTimerEnabled
        self.selectedWordPackIds = Self.normalizedPackIds(selectedWordPackIds)
        self.distributionMode = distributionMode
        self.cloudGuestVotingEnabled = cloudGuestVotingEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hostIsPlaying = try container.decodeIfPresent(Bool.self, forKey: .hostIsPlaying) ?? true
        ghostEnabled = try container.decodeIfPresent(Bool.self, forKey: .ghostEnabled) ?? false
        ghostPickAgainEnabled = try container.decodeIfPresent(Bool.self, forKey: .ghostPickAgainEnabled) ?? true
        showRoleOnCard = try container.decodeIfPresent(Bool.self, forKey: .showRoleOnCard) ?? false
        ghostMode = try container.decodeIfPresent(GhostMode.self, forKey: .ghostMode) ?? .classic
        mismatchGhostAlliance = try container.decodeIfPresent(Bool.self, forKey: .mismatchGhostAlliance) ?? false
        timerSeconds = try container.decodeIfPresent(Int.self, forKey: .timerSeconds) ?? 180
        discussionTimerEnabled = try container.decodeIfPresent(Bool.self, forKey: .discussionTimerEnabled) ?? false
        distributionMode = try container.decodeIfPresent(DistributionMode.self, forKey: .distributionMode) ?? .passThePhone
        cloudGuestVotingEnabled = try container.decodeIfPresent(Bool.self, forKey: .cloudGuestVotingEnabled) ?? false

        if let ids = try container.decodeIfPresent([String].self, forKey: .selectedWordPackIds),
           !ids.isEmpty {
            selectedWordPackIds = Self.normalizedPackIds(ids)
        } else if let legacyId = try container.decodeIfPresent(String.self, forKey: .wordPackId),
                  !legacyId.isEmpty {
            selectedWordPackIds = [legacyId]
        } else {
            selectedWordPackIds = Self.defaultSelectedWordPackIds
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hostIsPlaying, forKey: .hostIsPlaying)
        try container.encode(ghostEnabled, forKey: .ghostEnabled)
        try container.encode(ghostPickAgainEnabled, forKey: .ghostPickAgainEnabled)
        try container.encode(showRoleOnCard, forKey: .showRoleOnCard)
        try container.encode(ghostMode, forKey: .ghostMode)
        try container.encode(mismatchGhostAlliance, forKey: .mismatchGhostAlliance)
        try container.encode(timerSeconds, forKey: .timerSeconds)
        try container.encode(discussionTimerEnabled, forKey: .discussionTimerEnabled)
        try container.encode(selectedWordPackIds, forKey: .selectedWordPackIds)
        try container.encode(distributionMode, forKey: .distributionMode)
        try container.encode(cloudGuestVotingEnabled, forKey: .cloudGuestVotingEnabled)
    }

    static func normalizedPackIds(_ packIds: [String]) -> [String] {
        var seen = Set<String>()
        return packIds.filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
