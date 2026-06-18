import SwiftUI

enum AppColor {
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let accent = Color.accentColor

    static func avatar(_ color: AvatarColor) -> Color {
        switch color {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .gray: .gray
        }
    }
}
