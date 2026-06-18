import SwiftUI

struct PartyOutcomeAnimation: View {
    let insidersWon: Bool

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if insidersWon {
                    insiderWinCelebration(in: geo.size)
                } else {
                    insiderLossMood(in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            if insidersWon {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    @ViewBuilder
    private func insiderWinCelebration(in size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    AppColor.success.opacity(animate ? 0.28 : 0.14),
                    AppColor.warning.opacity(animate ? 0.16 : 0.08),
                    .clear
                ],
                center: .center,
                startRadius: 24,
                endRadius: size.width * 0.72
            )

            VStack(spacing: 22) {
                HStack(alignment: .bottom, spacing: 18) {
                    CartoonPandaView(mood: .dancing, size: 92, phase: 0, animate: animate)
                    CartoonPandaView(mood: .dancing, size: 108, phase: 0.35, animate: animate)
                    CartoonPandaView(mood: .dancing, size: 92, phase: 0.7, animate: animate)
                }

                Text("Panda party!")
                    .font(AppTypography.display)
                    .foregroundStyle(AppColor.label)
                    .shadow(color: AppColor.warning.opacity(0.35), radius: 8, y: 2)
                    .scaleEffect(animate ? 1.05 : 0.96)
            }
            .padding(.top, size.height * 0.1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func insiderLossMood(in size: CGSize) -> some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.14, green: 0.16, blue: 0.28).opacity(0.5),
                        Color(red: 0.08, green: 0.1, blue: 0.18).opacity(0.3),
                        .clear
                    ],
                    center: .top,
                    startRadius: 12,
                    endRadius: size.width * 0.8
                )

                softRain(time: time, in: size)

                VStack(spacing: 26) {
                    HStack(alignment: .bottom, spacing: 28) {
                        CartoonPandaView(mood: .crying, size: 96, phase: 0, animate: animate, time: time)
                        CartoonPandaView(mood: .crying, size: 112, phase: 0.5, animate: animate, time: time)
                    }

                    Text("Sniff…")
                        .font(AppTypography.display)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .opacity(animate ? 1 : 0.75)
                        .offset(y: animate ? 0 : 4)
                }
                .padding(.top, size.height * 0.1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func softRain(time: TimeInterval, in size: CGSize) -> some View {
        ForEach(0..<10, id: \.self) { index in
            let phase = Double(index) * 0.19
            let progress = (time * 0.28 + phase).truncatingRemainder(dividingBy: 1)
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: 2, height: 14)
                .position(
                    x: size.width * (0.1 + Double(index) * 0.085),
                    y: progress * size.height
                )
        }
    }
}

private struct CartoonPandaView: View {
    enum Mood {
        case dancing
        case crying
    }

    let mood: Mood
    var size: CGFloat
    var phase: Double
    var animate: Bool
    var time: TimeInterval = 0

    private var bounce: CGFloat { animate ? 1 : 0 }
    private var sway: Double { sin((time + phase) * 4.2) * (mood == .dancing ? 8 : 3) }

    var body: some View {
        let lift = mood == .dancing ? -10 * bounce : 2 * bounce
        let squash = mood == .dancing ? 1 + 0.06 * bounce : 1 - 0.04 * bounce

        VStack(spacing: size * 0.04) {
            if mood == .dancing {
                dancingArms
            }

            ZStack {
                pandaHead
                if mood == .crying {
                    cryingTears
                }
            }

            if mood == .dancing {
                dancingLegs
            } else {
                cryingArms
            }
        }
        .offset(y: lift)
        .scaleEffect(x: 1, y: squash)
        .rotationEffect(.degrees(sway))
        .animation(.easeInOut(duration: 0.55).delay(phase * 0.12), value: animate)
    }

    private var pandaHead: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 4)

            HStack(spacing: size * 0.28) {
                pandaEar
                pandaEar
            }
            .offset(y: -size * 0.42)

            HStack(spacing: size * 0.22) {
                eyePatch(mood: mood)
                eyePatch(mood: mood)
            }
            .offset(y: -size * 0.04)

            Ellipse()
                .fill(Color.black.opacity(0.85))
                .frame(width: size * 0.16, height: size * 0.11)
                .offset(y: size * 0.18)

            mouth
                .offset(y: size * 0.28)
        }
    }

    private var pandaEar: some View {
        Circle()
            .fill(Color.black.opacity(0.88))
            .frame(width: size * 0.24, height: size * 0.24)
    }

    @ViewBuilder
    private func eyePatch(mood: Mood) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.88))
                .frame(width: size * 0.26, height: size * 0.26)

            switch mood {
            case .dancing:
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.09, height: size * 0.09)
                    .offset(x: size * 0.03, y: -size * 0.02)
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.045, height: size * 0.045)
                    .offset(x: size * 0.04, y: -size * 0.015)
            case .crying:
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: size * 0.08, height: size * 0.05)
                    .offset(y: size * 0.02)
                sadBrow
            }
        }
    }

    private var sadBrow: some View {
        Capsule()
            .fill(Color.black.opacity(0.75))
            .frame(width: size * 0.12, height: size * 0.025)
            .rotationEffect(.degrees(18))
            .offset(x: -size * 0.02, y: -size * 0.1)
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .dancing:
            Arc(startAngle: .degrees(200), endAngle: .degrees(-20), clockwise: false)
                .stroke(Color.black.opacity(0.75), lineWidth: size * 0.035)
                .frame(width: size * 0.28, height: size * 0.16)
        case .crying:
            Arc(startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                .stroke(Color.black.opacity(0.75), lineWidth: size * 0.035)
                .frame(width: size * 0.22, height: size * 0.12)
        }
    }

    private var dancingArms: some View {
        HStack(spacing: size * 0.72) {
            danceArm(left: true)
            danceArm(left: false)
        }
        .offset(y: size * 0.08)
    }

    private func danceArm(left: Bool) -> some View {
        let angle = Double(left ? -1 : 1) * (animate ? 38 : 12)
        return Capsule()
            .fill(Color.black.opacity(0.88))
            .frame(width: size * 0.11, height: size * 0.34)
            .rotationEffect(.degrees(angle))
            .offset(y: animate ? -size * 0.08 : 0)
    }

    private var dancingLegs: some View {
        HStack(spacing: size * 0.18) {
            danceLeg(left: true)
            danceLeg(left: false)
        }
        .offset(y: -size * 0.06)
    }

    private func danceLeg(left: Bool) -> some View {
        let angle = Double(left ? -1 : 1) * (animate ? 14 : -8)
        return Capsule()
            .fill(Color.black.opacity(0.88))
            .frame(width: size * 0.12, height: size * 0.28)
            .rotationEffect(.degrees(angle))
    }

    private var cryingArms: some View {
        HStack(spacing: size * 0.52) {
            Capsule()
                .fill(Color.black.opacity(0.88))
                .frame(width: size * 0.1, height: size * 0.26)
                .rotationEffect(.degrees(animate ? 24 : 32))
            Capsule()
                .fill(Color.black.opacity(0.88))
                .frame(width: size * 0.1, height: size * 0.26)
                .rotationEffect(.degrees(animate ? -24 : -32))
        }
        .offset(y: -size * 0.08)
    }

    private var cryingTears: some View {
        HStack(spacing: size * 0.34) {
            fallingTear(phase: phase)
            fallingTear(phase: phase + 0.35)
        }
        .offset(y: size * 0.12)
    }

    private func fallingTear(phase: Double) -> some View {
        let progress = (time * 1.1 + phase).truncatingRemainder(dividingBy: 1)
        return Teardrop()
            .fill(Color.cyan.opacity(0.8))
            .frame(width: size * 0.08, height: size * 0.11)
            .offset(y: progress * size * 0.42)
            .opacity(progress > 0.82 ? 0 : 0.9)
    }
}

private struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: min(rect.width, rect.height) / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

private struct Teardrop: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.midY)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.midY)
        )
        return path
    }
}
