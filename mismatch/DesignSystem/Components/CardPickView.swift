import SwiftUI

struct ClaimedCard: Equatable, Sendable {
    let index: Int
    let playerName: String
}

struct CardPickView: View {
    let cardCount: Int
    let showRoleOnCard: Bool
    let assignment: RoleAssignment
    var insiderWord: String? = nil
    var claimedCards: [ClaimedCard] = []
    var nextPlayerName: String? = nil
    var showsInstructions: Bool = true
    let onComplete: (Int) -> Void

    @State private var phase: Phase = .pick
    @State private var selectedCardIndex: Int?
    @State private var isGhostBluffReveal = false

    private enum Phase {
        case pick
        case revealed
    }

    private var columns: [GridItem] {
        cardCount <= 3
            ? Array(repeating: GridItem(.flexible()), count: cardCount)
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var availableCardCount: Int {
        cardCount - claimedCards.count
    }

    private var canGhostRepick: Bool {
        assignment.role == .ghost && availableCardCount > 1 && !isGhostBluffReveal
    }

    private var showsGhostTruthReveal: Bool {
        assignment.role == .ghost && !isGhostBluffReveal
    }

    var body: some View {
        VStack(spacing: 24) {
            switch phase {
            case .pick:
                pickPhase
            case .revealed:
                revealedPhase
            }
        }
        .animation(.easeInOut(duration: 0.2), value: phase)
    }

    private var pickPhase: some View {
        VStack(spacing: 16) {
            if showsInstructions {
                Text("Pick a card to see your role")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
            }

            if !claimedCards.isEmpty {
                Text("Cards already taken are marked with names")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<cardCount, id: \.self) { index in
                    if let claimed = claimedCards.first(where: { $0.index == index }) {
                        takenCardView(name: claimed.playerName)
                    } else {
                        Button {
                            selectedCardIndex = index
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                phase = .revealed
                            }
                        } label: {
                            faceDownCard
                        }
                        .accessibilityLabel("Face-down card")
                    }
                }
            }
        }
    }

    private var revealedPhase: some View {
        VStack(spacing: 20) {
            if showsGhostTruthReveal {
                ghostTruthReveal
            } else if assignment.role == .ghost {
                ghostBluffReveal
            } else {
                standardRoleReveal
            }

            if canGhostRepick {
                SecondaryButton(title: "Pick again") {
                    isGhostBluffReveal = true
                    selectedCardIndex = nil
                    withAnimation {
                        phase = .pick
                    }
                }
            }

            PrimaryButton(title: nextButtonTitle) {
                finishPick()
            }
        }
        .transition(.opacity)
    }

    private var ghostTruthReveal: some View {
        Group {
            if showRoleOnCard {
                RoleBadgeView(role: assignment.role)
            }

            Text("No word — bluff from context")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)

            if let hint = assignment.categoryHint {
                Text("Hint: \(hint)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
    }

    private var ghostBluffReveal: some View {
        VStack(spacing: 12) {
            Text("Insider word")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)

            Text(insiderWord ?? "Unknown")
                .font(AppTypography.title)
                .foregroundStyle(AppColor.label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(AppColor.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                }

            Text("Same word the insiders have — memorize it for later.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var standardRoleReveal: some View {
        if showRoleOnCard {
            RoleBadgeView(role: assignment.role)
        }

        if let word = assignment.word {
            Text(word)
                .font(AppTypography.title)
                .foregroundStyle(AppColor.label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(AppColor.backgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                }
        }
    }

    private var nextButtonTitle: String {
        nextPlayerName == nil ? "Finish" : "Continue"
    }

    private func finishPick() {
        if let selectedCardIndex {
            onComplete(selectedCardIndex)
        }
    }

    private var faceDownCard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        AppColor.backgroundElevated,
                        AppColor.card
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 110)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                BrandPalette.insiderMid.opacity(0.45),
                                BrandPalette.ghostMid.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .overlay {
                Image(systemName: "questionmark")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
    }

    private func takenCardView(name: String) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppColor.card)
            .frame(height: 110)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(AppColor.secondaryLabel)
                    Text(name)
                        .font(AppTypography.title)
                        .foregroundStyle(AppColor.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                }
                .padding(.horizontal, 10)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColor.cardBorder, lineWidth: 1)
            }
            .accessibilityLabel("\(name)'s card")
    }
}
