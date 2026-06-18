import Foundation

struct HostPreferences: Codable, Equatable, Sendable {
    var discussionTimerEnabled: Bool
    var timerMinutes: Int

    static let allowedTimerMinutes = [1, 2, 3, 4, 5]
    static let `default` = HostPreferences(discussionTimerEnabled: false, timerMinutes: 3)

    var timerSeconds: Int {
        timerMinutes * 60
    }

    var summary: String {
        if discussionTimerEnabled {
            return timerMinutes == 1 ? "1 min discussion timer" : "\(timerMinutes) min discussion timer"
        }
        return "Discussion timer off"
    }

    func normalized() -> HostPreferences {
        var copy = self
        if !Self.allowedTimerMinutes.contains(copy.timerMinutes) {
            copy.timerMinutes = Self.default.timerMinutes
        }
        return copy
    }

    func applying(to settings: GameSettings) -> GameSettings {
        var updated = settings
        updated.discussionTimerEnabled = discussionTimerEnabled
        updated.timerSeconds = timerSeconds
        return updated
    }
}
