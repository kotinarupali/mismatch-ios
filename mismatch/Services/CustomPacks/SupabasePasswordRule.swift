import Foundation

// Matches the live Auth settings: 6 bytes minimum, no required character mix.
// GoTrue also rejects more than 72 bytes because bcrypt cannot store them.
enum SupabasePasswordRule {
    static let minimumLength = 6
    static let maximumLength = 72

    static func accepts(_ password: String) -> Bool {
        rejectionMessage(for: password) == nil
    }

    static func rejectionMessage(for password: String) -> String? {
        let length = password.utf8.count
        if length < minimumLength {
            return "Use at least 6 characters."
        }
        if length > maximumLength {
            return "Use at most 72 characters."
        }
        return nil
    }
}
