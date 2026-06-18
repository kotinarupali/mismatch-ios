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
                discussionStatusBar

                if viewModel.timerEnabled {
                    TimerView(
                        timeLabel: viewModel.timerService.formattedTime,
                        totalSeconds: viewModel.timerDurationSeconds
                    )
                }

                PlayerGridView(
                    players: viewModel.displayPlayers,
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

    @ViewBuilder
    private var discussionStatusBar: some View {
        HStack(alignment: .center, spacing: 12) {
            if let starterName = viewModel.discussionStarterName {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(AppColor.warning)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(starterName) starts")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.label)
                            .lineLimit(1)
                        Text("Go clockwise")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            OutsiderCountsBanner(
                mismatchCount: viewModel.remainingMismatchCount,
                ghostCount: viewModel.remainingGhostCount,
                countSuffix: "left",
                style: .compact,
                showsGhostCount: viewModel.ghostEnabled
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        DiscussionView(viewModel: DiscussionViewModel(dependencies: AppDependencies()))
    }
}
