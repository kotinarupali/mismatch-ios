import Foundation

enum CardDeliveryBackend: String, Codable, Sendable {
    case local
    case cloud
}

enum CloudCardConfig {
    private static let infoPlistKey = "MismatchCloudCardBaseURL"

    static var baseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    static var isConfigured: Bool {
        baseURL != nil
    }
}
