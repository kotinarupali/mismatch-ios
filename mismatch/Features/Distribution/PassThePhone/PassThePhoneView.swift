import SwiftUI

struct PassThePhoneView: View {
    @Bindable var viewModel: PassThePhoneViewModel
    @Bindable private var sessionStore: GameSessionStore

    init(viewModel: PassThePhoneViewModel) {
        self.viewModel = viewModel
        _sessionStore = Bindable(viewModel.gameSessionStore)
    }

    var body: some View {
        PlaceholderScreenLayout(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            showsBrandLogo: true,
            usesHeroTitle: viewModel.usesHeroTitle,
            roomStyle: .distribution
        ) {
            if viewModel.awaitingHandoff {
                handoffContent
            } else if viewModel.canShowCardPick, let assignment = viewModel.currentAssignment {
                CardPickView(
                    cardCount: viewModel.faceDownCardCount,
                    showRoleOnCard: viewModel.showRoleOnCard,
                    assignment: assignment,
                    insiderWord: viewModel.insiderWord,
                    claimedCards: sessionStore.claimedCards(),
                    nextPlayerName: viewModel.nextPlayerDisplayName,
                    showsInstructions: false,
                    canGhostRoleSwap: viewModel.canGhostRoleSwap,
                    onGhostRoleSwap: { viewModel.swapGhostRole() },
                    onComplete: { cardIndex, attemptedGhostRoleSwap in
                        viewModel.cardCompleted(
                            cardIndex: cardIndex,
                            attemptedGhostRoleSwap: attemptedGhostRoleSwap
                        )
                    }
                )
                .id(viewModel.currentPlayerId)
            } else if viewModel.isMissingRoleAssignments {
                VStack(spacing: 16) {
                    Text("Roles weren't dealt to any player.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .multilineTextAlignment(.center)

                    PrimaryButton(title: "Back to Lobby") {
                        viewModel.returnToLobby()
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                Text("Everyone has seen their card.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
        .navigationTitle("Roles")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
        .hostGameMenu(
            gameSessionStore: viewModel.gameSessionStore,
            onRepick: { viewModel.repickRoles() },
            onEndSession: { viewModel.endSessionTapped() },
            onCheckPlayerRole: { viewModel.checkPlayerRoleTapped() }
        )
        .sheet(isPresented: $viewModel.showPlayerRolePicker) {
            PlayerRolePickerSheet(players: viewModel.playersWithPickedCards) { player in
                viewModel.selectPlayerForRoleCheck(player)
            }
        }
        .sheet(item: $viewModel.playerToReveal) { player in
            PlayerRoleRevealSheet(player: player)
        }
    }

    private var handoffContent: some View {
        VStack(spacing: 28) {
            AvatarView(
                name: viewModel.currentPlayerDisplayName,
                color: viewModel.currentPlayerAvatarColor,
                size: 96
            )
            .padding(.top, 8)

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
