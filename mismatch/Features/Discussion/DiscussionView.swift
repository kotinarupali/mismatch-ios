import SwiftUI

struct DiscussionView: View {
    @Bindable var viewModel: DiscussionViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Discuss & Vote",
            subtitle: "Talk it out, then tap a player to eliminate.",
            icon: "bubble.left.and.bubble.right.fill",
            roomStyle: .discussion
        ) {
            VStack(spacing: 20) {
                OutsiderCountsBanner(
                    mismatchCount: viewModel.remainingMismatchCount,
                    ghostCount: viewModel.remainingGhostCount,
                    countSuffix: "left"
                )

                if let starterName = viewModel.discussionStarterName {
                    HStack(spacing: 10) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(AppColor.warning)
                            .clipShape(Circle())

                        Text("\(starterName) starts the discussion")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.label)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(AppColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                    }
                }

                if viewModel.timerEnabled {
                    TimerView(
                        timeLabel: viewModel.timerService.formattedTime,
                        totalSeconds: viewModel.timerDurationSeconds
                    )
                }

                PlayerGridView(
                    players: viewModel.allPlayers,
                    selectedPlayerId: viewModel.selectedPlayerId,
                    style: .tile,
                    showEliminatedRoleBadges: true,
                    discussionStarterId: viewModel.discussionStarterId,
                    onSelect: { viewModel.selectPlayer($0) }
                )

                PrimaryButton(
                    title: "Confirm Vote",
                    isEnabled: viewModel.canConfirmVote
                ) {
                    viewModel.confirmVoteTapped()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Discuss & Vote")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            onRepick: { viewModel.repickRoles() },
            onEndGame: { viewModel.endGame() },
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
        .confirmDialog(
            isPresented: $viewModel.showConfirmDialog,
            title: "Confirm elimination",
            message: "Eliminate \(viewModel.selectedPlayerName)?",
            confirmTitle: "Eliminate"
        ) {
            viewModel.submitElimination()
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

#Preview {
    NavigationStack {
        DiscussionView(viewModel: DiscussionViewModel(dependencies: AppDependencies()))
    }
}
