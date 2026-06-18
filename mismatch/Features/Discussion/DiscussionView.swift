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
                if viewModel.timerEnabled {
                    TimerView(
                        timeLabel: viewModel.timerService.formattedTime,
                        totalSeconds: viewModel.timerDurationSeconds
                    )
                }

                PlayerGridView(
                    players: viewModel.activePlayers,
                    selectedPlayerId: viewModel.selectedPlayerId,
                    onSelect: { viewModel.selectPlayer($0) }
                )

                PrimaryButton(
                    title: "Confirm Vote",
                    isEnabled: viewModel.selectedPlayerId != nil
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
