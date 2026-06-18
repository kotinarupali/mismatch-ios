import SwiftUI

struct RoleBadgeView: View {
    let role: Role

    var body: some View {
        Text(role.displayName)
            .font(AppTypography.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
            .accessibilityLabel("Role: \(role.displayName)")
    }

    private var badgeColor: Color {
        role.badgeColor
    }
}

struct RoleIconBadge: View {
    enum Size {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small: 22
            case .medium: 34
            case .large: 44
            }
        }

        var iconFontSize: CGFloat {
            switch self {
            case .small: 11
            case .medium: 15
            case .large: 19
            }
        }
    }

    let role: Role
    var size: Size = .small

    var body: some View {
        Image(systemName: role.iconName)
            .font(.system(size: size.iconFontSize, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size.dimension, height: size.dimension)
            .background(role.badgeColor)
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
            .accessibilityLabel(role.displayName)
    }
}

private extension Role {
    var iconName: String {
        switch self {
        case .insider: "checkmark"
        case .mismatch: "exclamationmark"
        case .ghost: "questionmark"
        }
    }

    var badgeColor: Color {
        switch self {
        case .insider: .green
        case .mismatch: .orange
        case .ghost: .purple
        }
    }
}
