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
    var canGhostRoleSwap: Bool = false
    var onGhostRoleSwap: (() -> RoleAssignment?)?
    let onComplete: (Int, Bool) -> Void

    @State private var phase: Phase = .pick
    @State private var selectedCardIndex: Int?
    @State private var isSeekingNewRole = false
    @State private var swappedAssignment: RoleAssignment?
    @State private var passedGhostCardIndex: Int?

    private enum Phase {
        case pick
        case revealed
    }

    private var displayAssignment: RoleAssignment {
        swappedAssignment ?? assignment
    }

    private var unpickedCardCount: Int {
        cardCount - claimedCards.count
    }

    private var columns: [GridItem] {
        cardCount <= 3
            ? Array(repeating: GridItem(.flexible()), count: cardCount)
            : [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var canGhostRepick: Bool {
        assignment.role == .ghost
            && swappedAssignment == nil
            && unpickedCardCount >= 2
            && !isSeekingNewRole
            && canGhostRoleSwap
    }

    private var showsGhostTruthReveal: Bool {
        displayAssignment.role == .ghost && !isSeekingNewRole && swappedAssignment == nil
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
                Text(isSeekingNewRole ? "Pick a different card — the ghost card stays open for someone else" : "Pick a card to see your role")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
            }

            if isSeekingNewRole, passedGhostCardIndex != nil {
                Text("You can't pick the ghost card again. Someone else will get that role.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            } else if !claimedCards.isEmpty {
                Text("Cards already taken are marked with names")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<cardCount, id: \.self) { index in
                    if let claimed = claimedCards.first(where: { $0.index == index }) {
                        takenCardView(name: claimed.playerName)
                    } else if isSeekingNewRole, index == passedGhostCardIndex {
                        passedGhostCardView
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
            } else {
                standardRoleReveal
            }

            if canGhostRepick {
                SecondaryButton(title: "Pick again for another role") {
                    guard let swapped = onGhostRoleSwap?() else { return }
                    swappedAssignment = swapped
                    passedGhostCardIndex = selectedCardIndex
                    isSeekingNewRole = true
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
                RoleBadgeView(role: displayAssignment.role)
            }

            Text("No word — bluff from context")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)

            if let hint = displayAssignment.categoryHint {
                Text("Hint: \(hint)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
    }

    @ViewBuilder
    private var standardRoleReveal: some View {
        if showRoleOnCard {
            RoleBadgeView(role: displayAssignment.role)
        }

        if let word = displayAssignment.word {
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
        guard let selectedCardIndex else { return }
        onComplete(selectedCardIndex, isSeekingNewRole)
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

    private var passedGhostCardView: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppColor.card)
            .frame(height: 110)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(BrandPalette.ghostMid.opacity(0.85))
                    Text("Still open")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(BrandPalette.ghostMid.opacity(0.45), lineWidth: 1)
            }
            .accessibilityLabel("Ghost card still open for another player")
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
