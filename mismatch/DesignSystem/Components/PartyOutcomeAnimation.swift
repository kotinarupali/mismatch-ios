import SwiftUI

struct PartyOutcomeAnimation: View {
    let insidersWon: Bool

    @State private var celebrate = false
    @State private var clink = false
    @State private var confettiWave = 0
    @State private var lossRun = false
    @State private var lossSplat = false
    @State private var lossCry = false
    @State private var lossImpact = false

    private let confettiPieces: [ConfettiPiece] = (0..<96).map { index in
        ConfettiPiece(
            id: index,
            xRatio: Double.random(in: 0...1),
            phase: Double.random(in: 0...1),
            speed: Double.random(in: 0.35...0.9),
            drift: Double.random(in: -40...40),
            spin: Double.random(in: 0...360),
            spinSpeed: Double.random(in: 120...420),
            color: [
                AppColor.accent, AppColor.accentSecondary, AppColor.warning,
                AppColor.success, Color(red: 1, green: 0.85, blue: 0.2),
                Color(red: 1, green: 0.4, blue: 0.55), .white
            ].randomElement() ?? AppColor.accent,
            width: CGFloat.random(in: 7...14),
            height: CGFloat.random(in: 10...22),
            isCircle: Bool.random()
        )
    }

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
                celebrate = true
                withAnimation(.easeInOut(duration: 0.28).repeatCount(5, autoreverses: true)) {
                    clink = true
                }
                Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { timer in
                    confettiWave += 1
                    if confettiWave > 8 {
                        timer.invalidate()
                    }
                }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                lossRun = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    lossImpact = true
                    lossSplat = true
                }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    lossCry = true
                }
            }
        }
    }

    @ViewBuilder
    private func insiderWinCelebration(in size: CGSize) -> some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                RadialGradient(
                    colors: [
                        AppColor.success.opacity(celebrate ? 0.35 : 0.15),
                        AppColor.warning.opacity(celebrate ? 0.2 : 0.08),
                        .clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: size.width * 0.75
                )

                ForEach(confettiPieces) { piece in
                    confettiShape(piece)
                        .position(confettiPosition(for: piece, time: time, in: size))
                        .rotationEffect(.degrees(piece.spin + time * piece.spinSpeed))
                }

                burstConfetti(in: size)

                VStack(spacing: 18) {
                    HStack(spacing: 0) {
                        cheersGlass(tilt: clink ? 18 : -10, mirrored: false)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AppColor.warning)
                            .scaleEffect(clink ? 1.35 : 0.7)
                            .opacity(clink ? 1 : 0.4)
                            .offset(y: clink ? -6 : 0)
                        cheersGlass(tilt: clink ? -18 : 10, mirrored: true)
                    }
                    .offset(y: celebrate ? -4 : 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.45), value: clink)

                    HStack(spacing: 20) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppColor.heroGradient)
                            .rotationEffect(.degrees(celebrate ? -12 : 12))
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(AppColor.warning)
                            .scaleEffect(celebrate ? 1.15 : 0.95)
                            .shadow(color: AppColor.warning.opacity(0.6), radius: 14, y: 4)
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppColor.heroGradient)
                            .scaleEffect(x: -1, y: 1)
                            .rotationEffect(.degrees(celebrate ? 12 : -12))
                    }

                    Text("Cheers!")
                        .font(AppTypography.display)
                        .foregroundStyle(AppColor.label)
                        .shadow(color: AppColor.warning.opacity(0.45), radius: 10, y: 2)
                        .scaleEffect(celebrate ? 1.06 : 0.94)
                }
                .padding(.top, size.height * 0.08)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func insiderLossMood(in size: CGSize) -> some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.15, green: 0.12, blue: 0.28).opacity(0.55),
                        Color(red: 0.08, green: 0.1, blue: 0.18).opacity(0.35),
                        .clear
                    ],
                    center: .top,
                    startRadius: 10,
                    endRadius: size.width * 0.85
                )

                rainDrops(time: time, in: size)

                VStack(spacing: 28) {
                    wallSplatScene(in: size)
                    cryingMartini(time: time)
                    Text("Oof.")
                        .font(AppTypography.display)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .opacity(lossSplat ? 1 : 0)
                        .scaleEffect(lossSplat ? 1 : 0.6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: lossSplat)
                }
                .padding(.top, size.height * 0.06)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    @ViewBuilder
    private func wallSplatScene(in size: CGSize) -> some View {
        let wallX = size.width * 0.62
        let runX = lossRun ? wallX - 54 : size.width * 0.08

        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .frame(width: 14, height: 130)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 28, height: 130)
                }
                .position(x: wallX, y: 72)
                .offset(x: lossImpact ? 3 : 0)
                .animation(.spring(response: 0.12, dampingFraction: 0.35), value: lossImpact)

            if lossImpact {
                ForEach(0..<8, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColor.warning.opacity(0.85))
                        .offset(
                            x: cos(Double(index) * .pi / 4) * 28,
                            y: sin(Double(index) * .pi / 4) * 22
                        )
                        .position(x: wallX - 8, y: 72)
                        .opacity(lossSplat ? 0.35 : 1)
                        .scaleEffect(lossSplat ? 0.4 : 1.2)
                        .animation(.easeOut(duration: 0.5), value: lossSplat)
                }
            }

            splatCartoon
                .position(x: runX, y: lossSplat ? 108 : 72)
                .animation(lossSplat ? .easeIn(duration: 0.35) : .easeOut(duration: 0.42), value: lossRun)
                .animation(.spring(response: 0.22, dampingFraction: 0.55), value: lossSplat)
        }
        .frame(height: 150)
        .frame(maxWidth: size.width * 0.92)
    }

    private var splatCartoon: some View {
        ZStack {
            if lossSplat {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 1, green: 0.82, blue: 0.35))
                    .frame(width: 88, height: 18)
                    .overlay {
                        HStack(spacing: 14) {
                            Circle().fill(.black.opacity(0.7)).frame(width: 5, height: 5)
                            Circle().fill(.black.opacity(0.7)).frame(width: 5, height: 5)
                            splatMouth
                        }
                    }
                    .rotationEffect(.degrees(-4))
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.88, blue: 0.45), Color(red: 1, green: 0.72, blue: 0.28)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay {
                        VStack(spacing: 6) {
                            HStack(spacing: 14) {
                                sadEye
                                sadEye
                            }
                            splatMouth
                        }
                        .offset(y: 2)
                    }
                    .scaleEffect(lossRun ? 1 : 0.85)
            }
        }
    }

    private var sadEye: some View {
        Capsule()
            .fill(.black.opacity(0.75))
            .frame(width: 8, height: 10)
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(Color.cyan.opacity(0.85))
                    .frame(width: 4, height: 4)
                    .offset(y: lossCry ? 10 : 4)
                    .opacity(lossCry ? 0.9 : 0)
            }
    }

    private var splatMouth: some View {
        Capsule()
            .fill(.black.opacity(0.65))
            .frame(width: 18, height: 4)
            .offset(y: 4)
    }

    @ViewBuilder
    private func cryingMartini(time: TimeInterval) -> some View {
        ZStack {
            Image(systemName: "wineglass")
                .font(.system(size: 64, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.75, green: 0.85, blue: 0.95), Color(red: 0.45, green: 0.58, blue: 0.78)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(lossCry ? -8 : 8))
                .offset(y: lossCry ? 2 : -2)
                .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: lossCry)

            HStack(spacing: 22) {
                fallingTear(time: time, phase: 0)
                fallingTear(time: time, phase: 0.45)
            }
            .offset(y: 18)

            Text("×")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.secondaryLabel.opacity(0.8))
                .offset(y: -28)
                .opacity(lossCry ? 1 : 0.2)
        }
    }

    @ViewBuilder
    private func fallingTear(time: TimeInterval, phase: Double) -> some View {
        let progress = (time * 0.9 + phase).truncatingRemainder(dividingBy: 1)
        Teardrop()
            .fill(Color.cyan.opacity(0.75))
            .frame(width: 10, height: 14)
            .offset(y: progress * 36)
            .opacity(progress > 0.85 ? 0 : 0.85)
    }

    @ViewBuilder
    private func rainDrops(time: TimeInterval, in size: CGSize) -> some View {
        ForEach(0..<14, id: \.self) { index in
            let phase = Double(index) * 0.17
            let progress = (time * 0.35 + phase).truncatingRemainder(dividingBy: 1)
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 3, height: 10)
                .position(
                    x: size.width * (0.08 + Double(index) * 0.065),
                    y: progress * size.height
                )
        }
    }

    @ViewBuilder
    private func cheersGlass(tilt: Double, mirrored: Bool) -> some View {
        Image(systemName: "wineglass.fill")
            .font(.system(size: 42))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 1, green: 0.92, blue: 0.55), AppColor.warning],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: AppColor.warning.opacity(0.5), radius: 8, y: 4)
            .rotationEffect(.degrees(tilt))
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
    }

    @ViewBuilder
    private func confettiShape(_ piece: ConfettiPiece) -> some View {
        Group {
            if piece.isCircle {
                Circle().fill(piece.color)
            } else {
                RoundedRectangle(cornerRadius: 2, style: .continuous).fill(piece.color)
            }
        }
        .frame(width: piece.width, height: piece.height)
        .shadow(color: piece.color.opacity(0.35), radius: 2, y: 1)
    }

    private func confettiPosition(for piece: ConfettiPiece, time: TimeInterval, in size: CGSize) -> CGPoint {
        let travel = size.height + 120
        let progress = (time * piece.speed + piece.phase).truncatingRemainder(dividingBy: 1)
        let y = -60 + progress * travel
        let sway = sin((time * 2.5) + piece.phase * 10) * piece.drift
        let x = piece.xRatio * size.width + sway
        return CGPoint(x: x, y: y)
    }

    @ViewBuilder
    private func burstConfetti(in size: CGSize) -> some View {
        ForEach(0..<(confettiWave * 12), id: \.self) { index in
            let piece = confettiPieces[index % confettiPieces.count]
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(piece.color)
                .frame(width: piece.width * 1.2, height: piece.height * 1.2)
                .rotationEffect(.degrees(Double(index) * 23))
                .position(x: size.width * 0.5, y: size.height * 0.22)
                .offset(
                    x: cos(Double(index) * 0.55) * (celebrate ? 140 : 20),
                    y: sin(Double(index) * 0.55) * (celebrate ? 100 : 10)
                )
                .opacity(celebrate ? 0 : 0.95)
                .animation(.easeOut(duration: 0.85), value: confettiWave)
        }
    }
}

private struct ConfettiPiece: Identifiable {
    let id: Int
    let xRatio: Double
    let phase: Double
    let speed: Double
    let drift: Double
    let spin: Double
    let spinSpeed: Double
    let color: Color
    let width: CGFloat
    let height: CGFloat
    let isCircle: Bool
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
