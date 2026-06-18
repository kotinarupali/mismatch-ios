import SwiftUI

struct PassThePhoneView: View {
    @Bindable var viewModel: PassThePhoneViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            icon: "iphone.and.arrow.forward",
            roomStyle: .distribution
        ) {
            if viewModel.awaitingHandoff {
                handoffContent
            } else if viewModel.canShowCardPick, let assignment = viewModel.currentAssignment {
                CardPickView(
                    cardCount: viewModel.faceDownCardCount,
                    showRoleOnCard: viewModel.showRoleOnCard,
                    assignment: assignment,
                    claimedCards: viewModel.claimedCards,
                    nextPlayerName: viewModel.nextPlayerDisplayName,
                    onComplete: { viewModel.cardCompleted(cardIndex: $0) }
                )
                .id(viewModel.currentPlayerId)
            } else {
                Text("Waiting for role assignment…")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
        .navigationTitle("Roles")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            onRepick: { viewModel.repickRoles() },
            onEndGame: { viewModel.endGame() }
        )
    }

    private var handoffContent: some View {
        VStack(spacing: 28) {
            AvatarView(
                name: viewModel.currentPlayerDisplayName,
                color: viewModel.currentPlayerAvatarColor,
                size: 80
            )
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(viewModel.currentPlayerDisplayName)
                    .font(AppTypography.display)
                    .foregroundStyle(AppColor.label)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("Your turn to pick a card")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
            }

            PrimaryButton(title: "I'm \(viewModel.currentPlayerDisplayName) — Pick my card") {
                viewModel.readyToPickTapped()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        PassThePhoneView(viewModel: PassThePhoneViewModel(dependencies: AppDependencies()))
    }
}
