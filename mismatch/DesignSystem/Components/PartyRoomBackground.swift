import SwiftUI

enum PartyRoomStyle {
    case home
    case lobby
    case discussion
    case voting
    case reveal
    case distribution

    var wallTop: Color {
        switch self {
        case .home: Color(red: 0.22, green: 0.12, blue: 0.34)
        case .lobby: Color(red: 0.18, green: 0.14, blue: 0.36)
        case .discussion: Color(red: 0.14, green: 0.16, blue: 0.32)
        case .voting: Color(red: 0.26, green: 0.12, blue: 0.24)
        case .reveal: Color(red: 0.20, green: 0.12, blue: 0.30)
        case .distribution: BrandPalette.navyTop
        }
    }

    var wallBottom: Color {
        switch self {
        case .home: Color(red: 0.12, green: 0.08, blue: 0.20)
        case .lobby: Color(red: 0.10, green: 0.09, blue: 0.22)
        case .discussion: Color(red: 0.09, green: 0.10, blue: 0.20)
        case .voting: Color(red: 0.16, green: 0.08, blue: 0.16)
        case .reveal: Color(red: 0.11, green: 0.08, blue: 0.18)
        case .distribution: BrandPalette.navyBottom
        }
    }

    var accentGlow: Color {
        switch self {
        case .home: Color(red: 0.95, green: 0.45, blue: 0.55)
        case .lobby: Color(red: 0.55, green: 0.40, blue: 1.0)
        case .discussion: Color(red: 0.35, green: 0.75, blue: 1.0)
        case .voting: Color(red: 1.0, green: 0.35, blue: 0.45)
        case .reveal: Color(red: 1.0, green: 0.75, blue: 0.30)
        case .distribution: BrandPalette.insiderMid
        }
    }
}

struct PartyRoomBackground: View {
    var style: PartyRoomStyle = .lobby

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                LinearGradient(
                    colors: [style.wallTop, style.wallBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Warm corner uplights — like lamps in a living room
                RadialGradient(
                    colors: [style.accentGlow.opacity(0.35), .clear],
                    center: .bottomLeading,
                    startRadius: 20,
                    endRadius: width * 0.75
                )

                RadialGradient(
                    colors: [AppColor.accent.opacity(0.32), .clear],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: width * 0.7
                )

                RadialGradient(
                    colors: [BrandPalette.mismatchMid.opacity(0.14), .clear],
                    center: UnitPoint(x: 0.12, y: 0.38),
                    startRadius: 10,
                    endRadius: width * 0.48
                )

                RadialGradient(
                    colors: [BrandPalette.ghostMid.opacity(0.16), .clear],
                    center: UnitPoint(x: 0.88, y: 0.34),
                    startRadius: 10,
                    endRadius: width * 0.45
                )

                if style == .distribution {
                    RadialGradient(
                        colors: [BrandPalette.mismatchMid.opacity(0.22), .clear],
                        center: UnitPoint(x: 0.18, y: 0.32),
                        startRadius: 10,
                        endRadius: width * 0.55
                    )
                    RadialGradient(
                        colors: [BrandPalette.ghostMid.opacity(0.24), .clear],
                        center: UnitPoint(x: 0.82, y: 0.28),
                        startRadius: 10,
                        endRadius: width * 0.5
                    )
                    RadialGradient(
                        colors: [BrandPalette.sadMid.opacity(0.16), .clear],
                        center: UnitPoint(x: 0.5, y: 0.62),
                        startRadius: 10,
                        endRadius: width * 0.45
                    )
                }

                // Floor
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.05, blue: 0.09).opacity(0),
                            Color(red: 0.05, green: 0.04, blue: 0.08),
                            Color(red: 0.03, green: 0.02, blue: 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: height * 0.28)
                }

                // Couch silhouettes
                VStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: 0) {
                        couchSilhouette(width: width * 0.42)
                        Spacer()
                        couchSilhouette(width: width * 0.36)
                            .opacity(0.7)
                    }
                    .padding(.horizontal, -8)
                    .padding(.bottom, height * 0.04)
                }

                // Bokeh
                bokehLayer(in: geo.size)

                // String lights across the ceiling
                stringLights(width: width)

                // Pennant bunting
                bunting(width: width)

                // Subtle confetti
                confettiLayer(in: geo.size)

                // Vignette for text legibility
                RadialGradient(
                    colors: [.clear, Color.black.opacity(0.32)],
                    center: .center,
                    startRadius: height * 0.2,
                    endRadius: height * 0.95
                )
            }
        }
        .ignoresSafeArea()
    }

    private func stringLights(width: CGFloat) -> some View {
        Canvas { context, size in
            let bulbCount = 11
            let y: CGFloat = 52
            let margin: CGFloat = 20
            let span = size.width - margin * 2
            let sag: CGFloat = 18

            var path = Path()
            path.move(to: CGPoint(x: margin, y: y - 4))
            for index in 0...bulbCount {
                let t = CGFloat(index) / CGFloat(bulbCount)
                let x = margin + span * t
                let sagY = y + sin(t * .pi) * sag
                path.addLine(to: CGPoint(x: x, y: sagY))
            }
            context.stroke(path, with: .color(.white.opacity(0.22)), lineWidth: 2)

            for index in 0...bulbCount {
                let t = CGFloat(index) / CGFloat(bulbCount)
                let x = margin + span * t
                let sagY = y + sin(t * .pi) * sag
                let hue = (index % 4)
                let color: Color = switch hue {
                case 0: Color(red: 1.0, green: 0.88, blue: 0.42)
                case 1: Color(red: 1.0, green: 0.52, blue: 0.68)
                case 2: Color(red: 0.52, green: 0.88, blue: 1.0)
                default: BrandPalette.insiderMid
                }
                let rect = CGRect(x: x - 6, y: sagY - 3, width: 12, height: 16)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                context.fill(
                    Path(ellipseIn: rect.insetBy(dx: -6, dy: -6)),
                    with: .color(color.opacity(0.32))
                )
            }
        }
        .frame(height: 100)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func bunting(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(0..<14, id: \.self) { index in
                Triangle()
                    .fill(buntingColor(index).opacity(0.72))
                    .frame(width: 22, height: 16)
                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 88)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func buntingColor(_ index: Int) -> Color {
        switch index % 5 {
        case 0: BrandPalette.mismatchMid
        case 1: BrandPalette.insiderMid
        case 2: BrandPalette.ghostMid
        case 3: BrandPalette.sadMid
        default: AppColor.accentSecondary
        }
    }

    private func bokehLayer(in size: CGSize) -> some View {
        ZStack {
            bokehSpot(color: BrandPalette.mismatchMid, size: style == .distribution ? 110 : 95, x: size.width * 0.12, y: size.height * 0.38)
            bokehSpot(color: BrandPalette.insiderMid, size: style == .distribution ? 100 : 88, x: size.width * 0.85, y: size.height * 0.40)
            bokehSpot(color: BrandPalette.ghostMid, size: style == .distribution ? 85 : 78, x: size.width * 0.52, y: size.height * 0.24)
            bokehSpot(color: BrandPalette.sadMid, size: style == .distribution ? 65 : 58, x: size.width * 0.30, y: size.height * 0.60)
            bokehSpot(color: AppColor.accentSecondary, size: 52, x: size.width * 0.72, y: size.height * 0.58)
        }
    }

    private func bokehSpot(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.22))
            .frame(width: size, height: size)
            .blur(radius: size * 0.32)
            .position(x: x, y: y)
    }

    private func confettiLayer(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let seeds: [(CGFloat, CGFloat, Color)] = [
                (0.12, 0.18, BrandPalette.mismatchMid),
                (0.88, 0.24, BrandPalette.sadMid),
                (0.72, 0.62, BrandPalette.ghostMid),
                (0.22, 0.72, BrandPalette.insiderMid),
                (0.48, 0.38, .white),
                (0.65, 0.15, AppColor.accentSecondary),
                (0.35, 0.48, AppColor.warning),
                (0.08, 0.42, BrandPalette.insiderMid),
                (0.92, 0.52, BrandPalette.mismatchMid),
                (0.55, 0.68, BrandPalette.ghostMid)
            ]
            for (rx, ry, color) in seeds {
                let rect = CGRect(x: rx * canvasSize.width, y: ry * canvasSize.height, width: 7, height: 11)
                var transform = CGAffineTransform.identity
                    .translatedBy(x: rect.midX, y: rect.midY)
                    .rotated(by: rx * 6)
                    .translatedBy(x: -rect.midX, y: -rect.midY)
                context.fill(Path(roundedRect: rect, cornerRadius: 1).applying(transform), with: .color(color.opacity(0.42)))
            }
        }
        .allowsHitTesting(false)
    }

    private func couchSilhouette(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black.opacity(0.35))
            .frame(width: width, height: 56)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.28))
                    .frame(height: 28)
                    .padding(.horizontal, 12)
                    .offset(y: -18)
            }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    PartyRoomBackground(style: .home)
}
