import Foundation

struct RoleAssignment: Codable, Equatable, Sendable {
    let role: Role
    let word: String?
    let categoryHint: String?

    init(role: Role, word: String? = nil, categoryHint: String? = nil) {
        self.role = role
        self.word = word
        self.categoryHint = categoryHint
    }
}
