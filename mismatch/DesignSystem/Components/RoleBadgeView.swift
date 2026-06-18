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
        case tiny
        case small
        case medium
        case large
        case extraLarge
        case hero

        var dimension: CGFloat {
            switch self {
            case .tiny: 22
            case .small: 34
            case .medium: 52
            case .large: 68
            case .extraLarge: 80
            case .hero: 96
            }
        }

        var iconScale: CGFloat {
            switch self {
            case .tiny: 0.58
            case .small: 0.62
            case .medium: 0.68
            case .large: 0.72
            case .extraLarge: 0.76
            case .hero: 0.8
            }
        }
    }

    let role: Role
    var size: Size = .small

    var body: some View {
        ZStack {
            Circle()
                .fill(roleGradient)
            Circle()
                .strokeBorder(.white.opacity(0.4), lineWidth: 1.5)

            roleIcon
                .scaleEffect(size.iconScale)
        }
        .frame(width: size.dimension, height: size.dimension)
        .shadow(color: roleShadowColor.opacity(size == .tiny ? 0.35 : 0.45), radius: size == .tiny ? 3 : 6, y: size == .tiny ? 1 : 3)
        .accessibilityLabel(role.displayName)
    }

    private var roleGradient: LinearGradient {
        switch role {
        case .insider:
            LinearGradient(
                colors: [
                    Color(red: 0.28, green: 0.95, blue: 0.68),
                    Color(red: 0.10, green: 0.72, blue: 0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .mismatch:
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.78, blue: 0.28),
                    Color(red: 0.98, green: 0.42, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .ghost:
            LinearGradient(
                colors: [
                    Color(red: 0.78, green: 0.58, blue: 1.0),
                    Color(red: 0.48, green: 0.32, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var roleShadowColor: Color {
        switch role {
        case .insider: Color(red: 0.12, green: 0.72, blue: 0.48)
        case .mismatch: Color(red: 0.98, green: 0.42, blue: 0.18)
        case .ghost: Color(red: 0.48, green: 0.32, blue: 0.88)
        }
    }

    @ViewBuilder
    private var roleIcon: some View {
        switch role {
        case .insider:
            InsiderGlyph()
                .foregroundStyle(.white)
                .frame(width: size.dimension * 0.86, height: size.dimension * 0.86)
        case .mismatch:
            MismatchGlyph()
                .foregroundStyle(.white)
                .frame(width: size.dimension * 0.88, height: size.dimension * 0.88)
        case .ghost:
            GhostGlyph()
                .foregroundStyle(.white)
                .frame(width: size.dimension * 0.68, height: size.dimension * 0.78)
        }
    }
}

/// Role artwork without the circular badge — for compact overlays on avatars.
struct RoleGlyphView: View {
    let role: Role
    var size: CGFloat = 18

    var body: some View {
        Group {
            switch role {
            case .insider:
                InsiderGlyph()
            case .mismatch:
                MismatchGlyph()
            case .ghost:
                GhostGlyph()
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(role.displayName)
    }
}

/// The correct card — one upright word card with a check (pairs with Mismatch's crossed wrong cards).
private struct InsiderGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: s * 0.08, style: .continuous)
                    .fill(.white)
                    .frame(width: s * 0.58, height: s * 0.74)
                    .shadow(color: .black.opacity(0.15), radius: 0.5, y: 0.5)

                VStack(spacing: s * 0.05) {
                    Capsule()
                        .fill(Color(red: 0.12, green: 0.52, blue: 0.28).opacity(0.45))
                        .frame(width: s * 0.32, height: s * 0.06)
                    Capsule()
                        .fill(Color(red: 0.12, green: 0.52, blue: 0.28).opacity(0.35))
                        .frame(width: s * 0.24, height: s * 0.06)

                    Image(systemName: "checkmark")
                        .font(.system(size: s * 0.22, weight: .black))
                        .foregroundStyle(Color(red: 0.08, green: 0.48, blue: 0.24))
                        .padding(.top, s * 0.02)
                }
                .offset(y: s * 0.02)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Two crossed cards — the "wrong word" vibe.
private struct MismatchGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: s * 0.08, style: .continuous)
                    .fill(.white.opacity(0.95))
                    .frame(width: s * 0.78, height: s * 0.5)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -s * 0.14, y: -s * 0.1)

                RoundedRectangle(cornerRadius: s * 0.08, style: .continuous)
                    .fill(.white.opacity(0.55))
                    .frame(width: s * 0.78, height: s * 0.5)
                    .rotationEffect(.degrees(14))
                    .offset(x: s * 0.18, y: s * 0.12)

                Image(systemName: "xmark")
                    .font(.system(size: s * 0.32, weight: .black))
                    .foregroundStyle(Color.orange)
                    .offset(x: s * 0.04, y: s * 0.04)
            }
            .frame(width: geo.size.width, height: geo.size.height)
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
