import SwiftUI

struct CardPickView: View {
    let showRoleOnCard: Bool
    let assignment: RoleAssignment
    let onComplete: () -> Void

    @State private var phase: Phase = .pick

    private enum Phase {
        case pick
        case revealed
    }

    private let cardCount = 4

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .pick:
                Text("Pick a card to see your role")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<cardCount, id: \.self) { _ in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                phase = .revealed
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppColor.heroGradient)
                                .frame(height: 110)
                                .overlay {
                                    Image(systemName: "questionmark")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .shadow(color: AppColor.accent.opacity(0.35), radius: 10, y: 6)
                        }
                        .accessibilityLabel("Face-down card")
                    }
                }

            case .revealed:
                VStack(spacing: 16) {
                    if showRoleOnCard {
                        RoleBadgeView(role: assignment.role)
                    }

                    if assignment.role == .ghost {
                        Text("No word — bluff from context")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.secondaryLabel)
                        if let hint = assignment.categoryHint {
                            Text("Hint: \(hint)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                        }
                    } else if let word = assignment.word {
                        HoldToRevealView(secret: word)
                    }

                    PrimaryButton(title: "Hide & Pass") {
                        onComplete()
                    }
                }
            }
        }
    }
}
