import SwiftUI

struct PartyOutcomeAnimation: View {
    var insidersWon: Bool = true
    var celebrationOnly: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if celebrationOnly || insidersWon {
                    winCelebration(in: geo.size)
                } else {
                    lossDrama(in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            if celebrationOnly || insidersWon {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    @ViewBuilder
    private func winCelebration(in size: CGSize) -> some View {
        ConfettiBurstView()
    }

    @ViewBuilder
    private func lossDrama(in size: CGSize) -> some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(LossFloater.all) { floater in
                    lossSymbol(floater, time: time, in: size)
                }
            }
        }
    }

    @ViewBuilder
    private func lossSymbol(_ floater: LossFloater, time: TimeInterval, in size: CGSize) -> some View {
        let progress = (time * floater.speed + floater.phase).truncatingRemainder(dividingBy: 1)
        let x = size.width * floater.xRatio + sin(time * 1.6 + floater.phase) * 18
        let y = size.height * (1.08 - progress * 1.15)
        let spin = Angle.degrees(time * floater.spin + floater.phase * 40)

        Group {
            switch floater.kind {
            case .mismatch:
                LossMismatchMark()
                    .frame(width: floater.scale, height: floater.scale)
            case .ghost:
                LossGhostMark()
                    .frame(width: floater.scale * 0.85, height: floater.scale)
            case .question:
                Text("?")
                    .font(.system(size: floater.scale, weight: .black, design: .rounded))
                    .foregroundStyle(AppColor.accentSecondary.opacity(0.55))
            }
        }
        .rotationEffect(spin)
        .opacity(0.35 + (1 - progress) * 0.45)
        .position(x: x, y: y)
    }
}

// MARK: - Confetti

private struct ConfettiBurstView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                for piece in ConfettiPiece.all {
                    let fall = (time * piece.speed + piece.phase).truncatingRemainder(dividingBy: 1.15)
                    let y = fall * (size.height + 60) - 30
                    let sway = sin(time * 2.4 + piece.phase) * 22
                    let x = piece.xRatio * size.width + sway
                    let spin = piece.rotation + time * piece.spinSpeed

                    var transform = CGAffineTransform.identity
                        .translatedBy(x: x, y: y)
                        .rotated(by: spin)
                    transform = transform.translatedBy(x: -piece.width / 2, y: -piece.height / 2)

                    let rect = CGRect(x: 0, y: 0, width: piece.width, height: piece.height)
                    let path: Path = piece.isCircle
                        ? Path(ellipseIn: rect)
                        : Path(roundedRect: rect, cornerRadius: 1.5)

                    context.fill(
                        path.applying(transform),
                        with: .color(piece.color.opacity(0.88))
                    )
                }
            }
        }
    }
}

private struct ConfettiPiece {
    let xRatio: CGFloat
    let speed: Double
    let phase: Double
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let rotation: Double
    let spinSpeed: Double
    let isCircle: Bool

    static let all: [ConfettiPiece] = {
        let palette: [Color] = [
            AppColor.accent,
            AppColor.accentSecondary,
            AppColor.success,
            AppColor.warning,
            .white,
            Color(red: 0.45, green: 0.75, blue: 1.0),
            Color(red: 1.0, green: 0.92, blue: 0.35)
        ]

        return (0..<54).map { index in
            let seed = Double(index)
            return ConfettiPiece(
                xRatio: CGFloat((seed * 0.137).truncatingRemainder(dividingBy: 1)),
                speed: 0.14 + (seed * 0.031).truncatingRemainder(dividingBy: 0.12),
                phase: (seed * 0.19).truncatingRemainder(dividingBy: 1),
                width: index.isMultiple(of: 3) ? 7 : 5,
                height: index.isMultiple(of: 4) ? 12 : 9,
                color: palette[index % palette.count],
                rotation: seed * 0.8,
                spinSpeed: 1.6 + (seed * 0.07).truncatingRemainder(dividingBy: 2),
                isCircle: index.isMultiple(of: 5)
            )
        }
    }()
}

// MARK: - Loss floaters

private struct LossFloater: Identifiable {
    enum Kind {
        case mismatch
        case ghost
        case question
    }

    let id: Int
    let kind: Kind
    let xRatio: CGFloat
    let speed: Double
    let phase: Double
    let scale: CGFloat
    let spin: Double

    static let all: [LossFloater] = [
        LossFloater(id: 0, kind: .mismatch, xRatio: 0.14, speed: 0.07, phase: 0.0, scale: 28, spin: 18),
        LossFloater(id: 1, kind: .ghost, xRatio: 0.32, speed: 0.05, phase: 0.22, scale: 32, spin: -12),
        LossFloater(id: 2, kind: .question, xRatio: 0.52, speed: 0.08, phase: 0.45, scale: 34, spin: 0),
        LossFloater(id: 3, kind: .mismatch, xRatio: 0.72, speed: 0.06, phase: 0.62, scale: 24, spin: 22),
        LossFloater(id: 4, kind: .ghost, xRatio: 0.86, speed: 0.09, phase: 0.15, scale: 30, spin: -16),
        LossFloater(id: 5, kind: .question, xRatio: 0.24, speed: 0.07, phase: 0.78, scale: 28, spin: 0),
        LossFloater(id: 6, kind: .mismatch, xRatio: 0.64, speed: 0.05, phase: 0.33, scale: 26, spin: 14),
        LossFloater(id: 7, kind: .ghost, xRatio: 0.44, speed: 0.08, phase: 0.88, scale: 36, spin: -10),
        LossFloater(id: 8, kind: .question, xRatio: 0.78, speed: 0.06, phase: 0.52, scale: 30, spin: 0)
    ]
}

private struct LossMismatchMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.orange.opacity(0.85))
                .frame(width: 18, height: 12)
                .rotationEffect(.degrees(-16))
                .offset(x: -3, y: -2)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.orange.opacity(0.45))
                .frame(width: 18, height: 12)
                .rotationEffect(.degrees(12))
                .offset(x: 3, y: 2)
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

private struct LossGhostMark: View {
    var body: some View {
        ZStack {
            LossGhostShape()
                .fill(Color(red: 0.55, green: 0.45, blue: 0.85).opacity(0.75))
            HStack(spacing: 4) {
                Circle().fill(Color.white.opacity(0.5)).frame(width: 3, height: 4)
                Circle().fill(Color.white.opacity(0.5)).frame(width: 3, height: 4)
            }
            .offset(y: -2)
        }
    }
}

private struct LossGhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.addEllipse(in: CGRect(x: w * 0.12, y: rect.minY, width: w * 0.76, height: h * 0.62))
        path.move(to: CGPoint(x: w * 0.12, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.92))
        path.addQuadCurve(to: CGPoint(x: w * 0.32, y: h * 0.74), control: CGPoint(x: w * 0.12, y: h * 0.8))
        path.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.92), control: CGPoint(x: w * 0.4, y: h))
        path.addQuadCurve(to: CGPoint(x: w * 0.72, y: h * 0.74), control: CGPoint(x: w * 0.64, y: h))
        path.addQuadCurve(to: CGPoint(x: w * 0.88, y: h * 0.92), control: CGPoint(x: w * 0.8, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.52))
        path.closeSubpath()
        return path
    }
}
