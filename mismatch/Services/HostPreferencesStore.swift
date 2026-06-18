import Foundation

@MainActor
final class HostPreferencesStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> HostPreferences {
        guard let data = defaults.data(forKey: UserDefaultsKeys.hostPreferences) else {
            return .default
        }
        guard let preferences = try? decoder.decode(HostPreferences.self, from: data) else {
            return .default
        }
        return preferences.normalized()
    }

    func save(_ preferences: HostPreferences) {
        let normalized = preferences.normalized()
        guard let data = try? encoder.encode(normalized) else { return }
        defaults.set(data, forKey: UserDefaultsKeys.hostPreferences)
    }
}
