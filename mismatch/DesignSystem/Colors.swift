import SwiftUI

enum AppColor {
    static let background = Color(red: 0.06, green: 0.07, blue: 0.14)
    static let backgroundElevated = Color(red: 0.10, green: 0.11, blue: 0.20)
    static let card = Color(red: 0.14, green: 0.15, blue: 0.26)
    static let cardSelected = Color(red: 0.20, green: 0.14, blue: 0.38)
    static let cardBorder = Color.white.opacity(0.08)
    static let label = Color.white
    static let secondaryLabel = Color.white.opacity(0.62)
    static let accent = Color(red: 0.55, green: 0.36, blue: 1.0)
    static let accentSecondary = Color(red: 0.98, green: 0.45, blue: 0.55)
    static let success = Color(red: 0.30, green: 0.85, blue: 0.65)
    static let warning = Color(red: 1.0, green: 0.72, blue: 0.35)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.45, green: 0.28, blue: 0.95),
            Color(red: 0.85, green: 0.32, blue: 0.58)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let screenGradient = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.09, blue: 0.18),
            Color(red: 0.12, green: 0.08, blue: 0.22),
            Color(red: 0.06, green: 0.07, blue: 0.14)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func avatar(_ color: AvatarColor) -> Color {
        switch color {
        case .red: Color(red: 0.95, green: 0.35, blue: 0.40)
        case .orange: Color(red: 1.0, green: 0.55, blue: 0.25)
        case .yellow: Color(red: 1.0, green: 0.78, blue: 0.25)
        case .green: Color(red: 0.30, green: 0.82, blue: 0.55)
        case .teal: Color(red: 0.25, green: 0.78, blue: 0.85)
        case .blue: Color(red: 0.35, green: 0.55, blue: 1.0)
        case .indigo: Color(red: 0.45, green: 0.40, blue: 0.95)
        case .purple: Color(red: 0.62, green: 0.38, blue: 0.95)
        case .pink: Color(red: 0.95, green: 0.45, blue: 0.75)
        case .gray: Color(red: 0.55, green: 0.58, blue: 0.68)
        }
    }
}

/// Shared brand colors — face-grid logo + matching room backgrounds.
enum BrandPalette {
    static let navyTop = Color(red: 0.10, green: 0.11, blue: 0.18)
    static let navyBottom = Color(red: 0.06, green: 0.07, blue: 0.12)

    static let mismatchLight = Color(red: 0.98, green: 0.55, blue: 0.50)
    static let mismatchMid = Color(red: 0.92, green: 0.38, blue: 0.34)
    static let mismatchDeep = Color(red: 0.72, green: 0.22, blue: 0.20)

    static let insiderLight = Color(red: 0.45, green: 1.0, blue: 0.82)
    static let insiderMid = Color(red: 0.22, green: 0.88, blue: 0.68)
    static let insiderDeep = Color(red: 0.08, green: 0.62, blue: 0.48)

    static let sadLight = Color(red: 1.0, green: 0.88, blue: 0.42)
    static let sadMid = Color(red: 1.0, green: 0.76, blue: 0.22)
    static let sadDeep = Color(red: 0.88, green: 0.58, blue: 0.08)

    static let ghostLight = Color(red: 0.88, green: 0.72, blue: 1.0)
    static let ghostMid = Color(red: 0.68, green: 0.48, blue: 0.98)
    static let ghostDeep = Color(red: 0.44, green: 0.26, blue: 0.82)
}
