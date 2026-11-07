import Foundation

// https://github.com/kotinarupali/mismatch-ios/issues/30
enum CustomPackConfig {
    static let requirePremium = false
    private static let urlKey = "MismatchSupabaseURL"
    private static let anonKeyName = "MismatchSupabaseAnonKey"

    static var supabaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: urlKey) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else { return nil }
        return url
    }

    static var anonKey: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: anonKeyName) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static var isConfigured: Bool {
        supabaseURL != nil && anonKey != nil
    }

    static var functionsURL: URL? {
        supabaseURL?.appendingPathSegments("functions/v1/word-packs")
    }
}

extension URL {
    func appendingPathSegments(_ path: String) -> URL {
        path.split(separator: "/").reduce(self) { url, segment in
            url.appendingPathComponent(String(segment))
        }
    }
}
