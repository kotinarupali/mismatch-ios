import Foundation

struct HostIdentityStore: Sendable {
    private let defaults: UserDefaults
    private let tokenKey = "customPackHostToken"
    private let accessTokenKey = "customPackAccessToken"
    private let refreshTokenKey = "customPackRefreshToken"
    private let userIDKey = "customPackUserID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hostToken: String {
        if let existing = defaults.string(forKey: tokenKey), !existing.isEmpty {
            return existing
        }
        let created = UUID().uuidString
        defaults.set(created, forKey: tokenKey)
        return created
    }

    var accessToken: String? {
        defaults.string(forKey: accessTokenKey)
    }

    var refreshToken: String? {
        defaults.string(forKey: refreshTokenKey)
    }

    var userID: String? {
        defaults.string(forKey: userIDKey)
    }

    var isSignedIn: Bool {
        accessToken != nil && userID != nil
    }

    func saveSession(accessToken: String, refreshToken: String, userID: String) {
        defaults.set(accessToken, forKey: accessTokenKey)
        defaults.set(refreshToken, forKey: refreshTokenKey)
        defaults.set(userID, forKey: userIDKey)
    }

    func clearSession() {
        defaults.removeObject(forKey: accessTokenKey)
        defaults.removeObject(forKey: refreshTokenKey)
        defaults.removeObject(forKey: userIDKey)
    }
}
