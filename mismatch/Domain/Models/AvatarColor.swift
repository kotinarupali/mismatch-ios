import Foundation

enum AvatarColor: String, Codable, CaseIterable, Sendable {
    case red
    case orange
    case yellow
    case green
    case teal
    case blue
    case indigo
    case purple
    case pink
    case gray

    static func forIndex(_ index: Int) -> AvatarColor {
        allCases[index % allCases.count]
    }
}
