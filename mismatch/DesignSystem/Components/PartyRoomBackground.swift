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
        case .home: Color(red: 0.18, green: 0.10, blue: 0.28)
        case .lobby: Color(red: 0.14, green: 0.12, blue: 0.30)
        case .discussion: Color(red: 0.10, green: 0.14, blue: 0.26)
        case .voting: Color(red: 0.22, green: 0.10, blue: 0.18)
        case .reveal: Color(red: 0.16, green: 0.10, blue: 0.24)
        case .distribution: Color(red: 0.12, green: 0.16, blue: 0.28)
        }
    }

    var wallBottom: Color {
        switch self {
        case .home: Color(red: 0.10, green: 0.08, blue: 0.16)
        case .lobby: Color(red: 0.08, green: 0.09, blue: 0.18)
        case .discussion: Color(red: 0.07, green: 0.10, blue: 0.16)
        case .voting: Color(red: 0.14, green: 0.07, blue: 0.12)
        case .reveal: Color(red: 0.09, green: 0.07, blue: 0.14)
        case .distribution: Color(red: 0.08, green: 0.10, blue: 0.18)
        }
    }

    var accentGlow: Color {
        switch self {
        case .home: Color(red: 0.95, green: 0.45, blue: 0.55)
        case .lobby: Color(red: 0.55, green: 0.40, blue: 1.0)
        case .discussion: Color(red: 0.35, green: 0.75, blue: 1.0)
        case .voting: Color(red: 1.0, green: 0.35, blue: 0.45)
        case .reveal: Color(red: 1.0, green: 0.75, blue: 0.30)
        case .distribution: Color(red: 0.45, green: 0.85, blue: 0.65)
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
                    colors: [AppColor.accent.opacity(0.28), .clear],
                    center: .bottomTrailing,
                    startRadius: 20,
                    endRadius: width * 0.7
                )

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
                    colors: [.clear, Color.black.opacity(0.45)],
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
            context.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 2)

            for index in 0...bulbCount {
                let t = CGFloat(index) / CGFloat(bulbCount)
                let x = margin + span * t
                let sagY = y + sin(t * .pi) * sag
                let hue = (index % 3)
                let color: Color = switch hue {
                case 0: Color(red: 1.0, green: 0.85, blue: 0.45)
                case 1: Color(red: 1.0, green: 0.55, blue: 0.65)
                default: Color(red: 0.55, green: 0.85, blue: 1.0)
                }
                let rect = CGRect(x: x - 5, y: sagY - 2, width: 10, height: 14)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                context.fill(
                    Path(ellipseIn: rect.insetBy(dx: -4, dy: -4)),
                    with: .color(color.opacity(0.25))
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
                    .fill(buntingColor(index).opacity(0.55))
                    .frame(width: 22, height: 16)
                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 88)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func buntingColor(_ index: Int) -> Color {
        switch index % 4 {
        case 0: AppColor.accent
        case 1: AppColor.accentSecondary
        case 2: AppColor.warning
        default: AppColor.success
        }
    }

    private func bokehLayer(in size: CGSize) -> some View {
        ZStack {
            bokehSpot(color: style.accentGlow, size: 120, x: size.width * 0.15, y: size.height * 0.35)
            bokehSpot(color: AppColor.accent, size: 90, x: size.width * 0.82, y: size.height * 0.42)
            bokehSpot(color: AppColor.warning, size: 70, x: size.width * 0.55, y: size.height * 0.22)
            bokehSpot(color: AppColor.success, size: 50, x: size.width * 0.28, y: size.height * 0.58)
        }
    }

    private func bokehSpot(color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.18))
            .frame(width: size, height: size)
            .blur(radius: size * 0.35)
            .position(x: x, y: y)
    }

    private func confettiLayer(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let seeds: [(CGFloat, CGFloat, Color)] = [
                (0.12, 0.18, AppColor.accentSecondary),
                (0.88, 0.24, AppColor.warning),
                (0.72, 0.62, AppColor.accent),
                (0.22, 0.72, AppColor.success),
                (0.48, 0.38, .white),
                (0.65, 0.15, AppColor.accentSecondary),
                (0.35, 0.48, AppColor.warning)
            ]
            for (rx, ry, color) in seeds {
                let rect = CGRect(x: rx * canvasSize.width, y: ry * canvasSize.height, width: 6, height: 10)
                var transform = CGAffineTransform.identity
                    .translatedBy(x: rect.midX, y: rect.midY)
                    .rotated(by: rx * 6)
                    .translatedBy(x: -rect.midX, y: -rect.midY)
                context.fill(Path(roundedRect: rect, cornerRadius: 1).applying(transform), with: .color(color.opacity(0.35)))
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
