import Foundation

struct HostPreferences: Codable, Equatable, Sendable {
    var discussionTimerEnabled: Bool
    var timerMinutes: Int
    var hostDisplayName: String

    static let allowedTimerMinutes = [1, 2, 3, 4, 5]
    static let defaultHostDisplayName = "Host"
    static let `default` = HostPreferences(
        discussionTimerEnabled: false,
        timerMinutes: 3,
        hostDisplayName: ""
    )

    var timerSeconds: Int {
        timerMinutes * 60
    }

    var resolvedHostDisplayName: String {
        let trimmed = hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultHostDisplayName : trimmed
    }

    var summary: String {
        if discussionTimerEnabled {
            return timerMinutes == 1 ? "1 min discussion timer" : "\(timerMinutes) min discussion timer"
        }
        return "Discussion timer off"
    }

    init(
        discussionTimerEnabled: Bool,
        timerMinutes: Int,
        hostDisplayName: String = ""
    ) {
        self.discussionTimerEnabled = discussionTimerEnabled
        self.timerMinutes = timerMinutes
        self.hostDisplayName = hostDisplayName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        discussionTimerEnabled = try container.decode(Bool.self, forKey: .discussionTimerEnabled)
        timerMinutes = try container.decode(Int.self, forKey: .timerMinutes)
        hostDisplayName = try container.decodeIfPresent(String.self, forKey: .hostDisplayName) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(discussionTimerEnabled, forKey: .discussionTimerEnabled)
        try container.encode(timerMinutes, forKey: .timerMinutes)
        try container.encode(hostDisplayName, forKey: .hostDisplayName)
    }

    func normalized() -> HostPreferences {
        var copy = self
        if !Self.allowedTimerMinutes.contains(copy.timerMinutes) {
            copy.timerMinutes = Self.default.timerMinutes
        }
        copy.hostDisplayName = copy.hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return copy
    }

    func applying(to settings: GameSettings) -> GameSettings {
        var updated = settings
        updated.discussionTimerEnabled = discussionTimerEnabled
        updated.timerSeconds = timerSeconds
        return updated
    }

    private enum CodingKeys: String, CodingKey {
        case discussionTimerEnabled
        case timerMinutes
        case hostDisplayName
    }
}
