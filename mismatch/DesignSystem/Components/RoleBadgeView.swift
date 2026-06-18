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
        switch role {
        case .insider: .green
        case .mismatch: .orange
        case .ghost: .purple
        }
    }
}
