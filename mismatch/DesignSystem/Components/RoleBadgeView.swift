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
            case .small: 28
            case .medium: 44
            case .large: 56
            }
        }

        var iconScale: CGFloat {
            switch self {
            case .small: 0.58
            case .medium: 0.64
            case .large: 0.68
            }
        }
    }

    let role: Role
    var size: Size = .small

    var body: some View {
        ZStack {
            Circle()
                .fill(role.badgeColor)
            Circle()
                .strokeBorder(.white.opacity(0.35), lineWidth: 1)

            roleIcon
                .scaleEffect(size.iconScale)
        }
        .frame(width: size.dimension, height: size.dimension)
        .accessibilityLabel(role.displayName)
    }

    @ViewBuilder
    private var roleIcon: some View {
        switch role {
        case .insider:
            InsiderGlyph()
                .foregroundStyle(.white)
                .frame(width: size.dimension * 0.68, height: size.dimension * 0.68)
        case .mismatch:
            MismatchGlyph()
                .foregroundStyle(.white)
                .frame(width: size.dimension * 0.72, height: size.dimension * 0.72)
        case .ghost:
            GhostGlyph()
                .foregroundStyle(.white)
                .frame(width: size.dimension * 0.62, height: size.dimension * 0.72)
        }
    }
}

/// The correct card — one upright word card with a check (pairs with Mismatch's crossed wrong cards).
private struct InsiderGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(.white)
                .frame(width: 15, height: 19)
                .shadow(color: .black.opacity(0.15), radius: 0.5, y: 0.5)

            VStack(spacing: 2.5) {
                Capsule()
                    .fill(Color(red: 0.12, green: 0.52, blue: 0.28).opacity(0.45))
                    .frame(width: 8, height: 1.5)
                Capsule()
                    .fill(Color(red: 0.12, green: 0.52, blue: 0.28).opacity(0.35))
                    .frame(width: 6, height: 1.5)

                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color(red: 0.08, green: 0.48, blue: 0.24))
                    .padding(.top, 1)
            }
            .offset(y: 0.5)
        }
    }
}

/// Two crossed lines — the "wrong word" vibe.
private struct MismatchGlyph: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(.white.opacity(0.95))
                .frame(width: 16, height: 11)
                .rotationEffect(.degrees(-18))
                .offset(x: -3, y: -2)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(.white.opacity(0.55))
                .frame(width: 16, height: 11)
                .rotationEffect(.degrees(14))
                .offset(x: 4, y: 3)

            Image(systemName: "xmark")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(Color.orange)
                .offset(x: 1, y: 1)
        }
    }
}

/// Classic sheet ghost silhouette.
private struct GhostGlyph: View {
    var body: some View {
        ZStack {
            GhostSilhouette()
                .fill(.white)

            HStack(spacing: 5) {
                Circle()
                    .fill(Color(red: 0.36, green: 0.28, blue: 0.62))
                    .frame(width: 4, height: 5)
                Circle()
                    .fill(Color(red: 0.36, green: 0.28, blue: 0.62))
                    .frame(width: 4, height: 5)
            }
            .offset(y: -2)
        }
    }
}

private struct GhostSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.addEllipse(in: CGRect(x: w * 0.12, y: rect.minY, width: w * 0.76, height: h * 0.62))

        path.move(to: CGPoint(x: w * 0.12, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.9))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.3, y: h * 0.72),
            control: CGPoint(x: w * 0.12, y: h * 0.78)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.9),
            control: CGPoint(x: w * 0.38, y: h * 0.98)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.7, y: h * 0.72),
            control: CGPoint(x: w * 0.62, y: h * 0.98)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.9),
            control: CGPoint(x: w * 0.78, y: h * 0.78)
        )
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.52))
        path.closeSubpath()

        return path
    }
}

private extension Role {
    var badgeColor: Color {
        switch self {
        case .insider: .green
        case .mismatch: .orange
        case .ghost: Color(red: 0.36, green: 0.28, blue: 0.62)
        }
    }
}
