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
            Text("Pick a card to see your role")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)

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

            if let nextPlayerName {
                passToBanner(name: nextPlayerName)
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
        if let nextPlayerName {
            return "Pass to \(nextPlayerName)"
        }
        return "Finish"
    }

    private func finishPick() {
        if let selectedCardIndex {
            onComplete(selectedCardIndex)
        }
    }

    private var faceDownCard: some View {
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

    private func takenCardView(name: String) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppColor.card)
            .frame(height: 110)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppColor.secondaryLabel)
                    Text(name)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColor.cardBorder, lineWidth: 1)
            }
            .accessibilityLabel("\(name)'s card")
    }

    private func passToBanner(name: String) -> some View {
        VStack(spacing: 6) {
            Text("Pass the phone to")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
            Text(name)
                .font(AppTypography.display)
                .foregroundStyle(AppColor.label)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(AppColor.card.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppColor.accent.opacity(0.4), lineWidth: 1)
        }
    }
}
