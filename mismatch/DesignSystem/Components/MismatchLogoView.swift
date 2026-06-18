import SwiftUI

/// Mismatch brand mark — bold, playful 2×2 face grid.
struct MismatchLogoView: View {
    enum Style {
        case faceGrid
        case mini
    }

    var size: CGFloat = 88
    var style: Style = .faceGrid
    var showsShadow: Bool = true

    var body: some View {
        switch style {
        case .faceGrid:
            faceGridLogo
        case .mini:
            miniLogo
        }
    }

    private var faceGridLogo: some View {
        let gap = size * 0.05
        let tile = (size - gap) / 2

        return ZStack {
            if showsShadow {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                BrandPalette.ghostMid.opacity(0.35),
                                BrandPalette.mismatchMid.opacity(0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.62
                        )
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                    .blur(radius: size * 0.04)
            }

            VStack(spacing: gap) {
                HStack(spacing: gap) {
                    LogoFaceTile(kind: .mismatch, size: tile, rotation: -7, showsShadow: showsShadow)
                    LogoFaceTile(kind: .insider, size: tile, rotation: 6, showsShadow: showsShadow)
                }
                HStack(spacing: gap) {
                    LogoFaceTile(kind: .sad, size: tile, rotation: -5, showsShadow: showsShadow)
                    LogoFaceTile(kind: .ghost, size: tile, rotation: 8, showsShadow: showsShadow, highlighted: true)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Mismatch")
    }

    private var miniLogo: some View {
        faceGridLogo
    }
}

private enum LogoFaceKind {
    case mismatch
    case insider
    case sad
    case ghost

    var gradient: [Color] {
        switch self {
        case .mismatch:
            [Color(red: 1.0, green: 0.58, blue: 0.52), BrandPalette.mismatchMid, Color(red: 0.78, green: 0.18, blue: 0.16)]
        case .insider:
            [Color(red: 0.52, green: 1.0, blue: 0.82), BrandPalette.insiderMid, Color(red: 0.02, green: 0.68, blue: 0.50)]
        case .sad:
            [Color(red: 1.0, green: 0.92, blue: 0.38), BrandPalette.sadMid, Color(red: 0.92, green: 0.58, blue: 0.04)]
        case .ghost:
            [Color(red: 0.92, green: 0.74, blue: 1.0), BrandPalette.ghostMid, Color(red: 0.48, green: 0.22, blue: 0.88)]
        }
    }

    var glow: Color {
        switch self {
        case .mismatch: Color(red: 1.0, green: 0.42, blue: 0.36)
        case .insider: Color(red: 0.18, green: 0.98, blue: 0.72)
        case .sad: Color(red: 1.0, green: 0.72, blue: 0.12)
        case .ghost: Color(red: 0.78, green: 0.52, blue: 1.0)
        }
    }

    var ink: Color {
        switch self {
        case .mismatch: Color(red: 0.22, green: 0.08, blue: 0.10)
        case .insider: Color(red: 0.02, green: 0.28, blue: 0.20)
        case .sad: Color(red: 0.28, green: 0.16, blue: 0.04)
        case .ghost: Color(red: 0.38, green: 0.14, blue: 0.52)
        }
    }
}

private struct LogoFaceTile: View {
    let kind: LogoFaceKind
    let size: CGFloat
    var rotation: Double = 0
    var showsShadow: Bool = true
    var highlighted: Bool = false

    private var cornerRadius: CGFloat { size * 0.28 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: kind.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay { tileShine }
                .overlay { tileBorder }
                .shadow(color: showsShadow ? kind.glow.opacity(0.72) : .clear, radius: size * 0.16, y: size * 0.08)
                .shadow(color: showsShadow ? .black.opacity(0.24) : .clear, radius: size * 0.05, y: size * 0.04)

            faceContent
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
    }

    private var tileShine: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.white.opacity(0.48), .white.opacity(0.12), .clear],
                    startPoint: .topLeading,
                    endPoint: UnitPoint(x: 0.58, y: 0.72)
                )
            )
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: highlighted
                        ? [.white, .white.opacity(0.65)]
                        : [.white.opacity(0.88), .white.opacity(0.32)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: highlighted ? max(2, size * 0.055) : max(1.6, size * 0.04)
            )
    }

    @ViewBuilder
    private var faceContent: some View {
        switch kind {
        case .mismatch: mismatchFace
        case .insider: insiderFace
        case .sad: sadFace
        case .ghost: ghostFace
        }
    }

    private var lineWidth: CGFloat { max(2, size * 0.055) }

    private var mismatchFace: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: size * 0.56, height: size * 0.56)
                .shadow(color: .black.opacity(0.08), radius: 1, y: 1)

            Circle()
                .fill(kind.ink)
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(x: -size * 0.11, y: -size * 0.05)

            Capsule()
                .fill(kind.ink)
                .frame(width: size * 0.17, height: size * 0.055)
                .rotationEffect(.degrees(-22))
                .offset(x: size * 0.11, y: -size * 0.05)

            PlayfulArc()
                .stroke(kind.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size * 0.14, height: size * 0.07)
                .rotationEffect(.degrees(180))
                .offset(y: size * 0.11)
        }
    }

    private var insiderFace: some View {
        ZStack {
            PlayfulArc()
                .stroke(kind.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size * 0.16, height: size * 0.08)
                .rotationEffect(.degrees(180))
                .offset(x: -size * 0.13, y: -size * 0.07)

            PlayfulArc()
                .stroke(kind.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size * 0.16, height: size * 0.08)
                .rotationEffect(.degrees(180))
                .offset(x: size * 0.13, y: -size * 0.07)

            PlayfulArc()
                .stroke(kind.ink, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size * 0.22, height: size * 0.11)
                .offset(y: size * 0.11)
        }
    }

    private var sadFace: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 1.0, green: 0.96, blue: 0.68))
                .frame(width: size * 0.58, height: size * 0.52)
                .overlay {
                    Ellipse()
                        .strokeBorder(.white.opacity(0.35), lineWidth: max(1, size * 0.02))
                }

            Circle()
                .fill(kind.ink)
                .frame(width: size * 0.075, height: size * 0.075)
                .offset(x: -size * 0.11, y: -size * 0.05)

            Circle()
                .fill(kind.ink)
                .frame(width: size * 0.075, height: size * 0.075)
                .offset(x: size * 0.11, y: -size * 0.05)

            PlayfulArc()
                .stroke(kind.ink, style: StrokeStyle(lineWidth: lineWidth * 0.85, lineCap: .round))
                .frame(width: size * 0.12, height: size * 0.06)
                .rotationEffect(.degrees(180))
                .offset(y: size * 0.11)

            Circle()
                .fill(Color(red: 0.35, green: 0.72, blue: 0.98))
                .frame(width: size * 0.07, height: size * 0.07)
                .offset(x: size * 0.16, y: size * 0.03)
        }
    }

    private var ghostFace: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.88, green: 0.72, blue: 1.0))
                .frame(width: size * 0.58, height: size * 0.58)

            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.72).opacity(0.55))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -size * 0.14, y: size * 0.04)

            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.72).opacity(0.55))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: size * 0.14, y: size * 0.04)

            Circle()
                .fill(.white)
                .frame(width: size * 0.13, height: size * 0.13)
                .offset(x: -size * 0.11, y: -size * 0.07)

            Capsule()
                .fill(.white)
                .frame(width: size * 0.14, height: size * 0.055)
                .rotationEffect(.degrees(-18))
                .offset(x: size * 0.11, y: -size * 0.07)

            Ellipse()
                .fill(Color(red: 1.0, green: 0.48, blue: 0.68))
                .frame(width: size * 0.2, height: size * 0.15)
                .offset(y: size * 0.13)

            Ellipse()
                .fill(Color(red: 0.62, green: 0.22, blue: 0.72))
                .frame(width: size * 0.1, height: size * 0.06)
                .offset(y: size * 0.15)
        }
    }
}

private struct PlayfulArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: .degrees(205),
            endAngle: .degrees(-25),
            clockwise: false
        )
        return path
    }
}

#Preview("Face grid") {
    VStack(spacing: 28) {
        MismatchLogoView(size: 108)
        MismatchLogoView(size: 56, style: .mini)
    }
    .padding(32)
    .background(AppColor.background)
}
