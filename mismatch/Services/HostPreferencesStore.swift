import Foundation
import UIKit

@MainActor
final class HostPreferencesStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let hostPlayerIDKey = "stableHostPlayerID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// The same host player for every game on this phone.
    func stableHostPlayerID() -> UUID {
        if let raw = defaults.string(forKey: hostPlayerIDKey), let id = UUID(uuidString: raw) {
            return id
        }
        let created = UIDevice.current.identifierForVendor ?? UUID()
        defaults.set(created.uuidString, forKey: hostPlayerIDKey)
        return created
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
