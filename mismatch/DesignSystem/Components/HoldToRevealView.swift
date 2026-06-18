import SwiftUI

struct HoldToRevealView: View {
    let secret: String
    @State private var isRevealed = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColor.secondaryBackground)
                    .frame(height: 80)

                Text(isRevealed ? secret : "Hold to reveal")
                    .font(AppTypography.title)
                    .foregroundStyle(isRevealed ? AppColor.label : AppColor.secondaryLabel)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isRevealed = true }
                    .onEnded { _ in isRevealed = false }
            )
            .accessibilityLabel(isRevealed ? secret : "Hold to reveal your word")

            Text("Release to hide")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
        }
    }
}
