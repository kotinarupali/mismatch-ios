import SwiftUI

struct TimerView: View {
    let timeLabel: String
    var totalSeconds: Int = 180

    private var progress: Double {
        let parts = timeLabel.split(separator: ":")
        guard parts.count == 2,
              let minutes = Int(parts[0]),
              let seconds = Int(parts[1]) else { return 0 }
        let remaining = minutes * 60 + seconds
        return max(0, min(1, Double(remaining) / Double(totalSeconds)))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.card, lineWidth: 12)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AppColor.heroGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: timeLabel)

            VStack(spacing: 4) {
                Text(timeLabel)
                    .font(AppTypography.display)
                    .monospacedDigit()
                    .foregroundStyle(AppColor.label)
                Text("remaining")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
        .accessibilityLabel("Timer \(timeLabel)")
        .padding(.vertical, 8)
    }
}
