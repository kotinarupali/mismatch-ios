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

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<cardCount, id: \.self) { _ in
                        Button {
                            withAnimation { phase = .revealed }
                        } label: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColor.accent.opacity(0.85))
                                .frame(height: 100)
                                .overlay {
                                    Image(systemName: "questionmark")
                                        .font(.title)
                                        .foregroundStyle(.white)
                                }
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
