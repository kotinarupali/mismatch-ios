import SwiftUI

struct VotingView: View {
    @Bindable var viewModel: VotingViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Voting",
            subtitle: "Tap a player to eliminate.",
            icon: "hand.raised.fill",
            roomStyle: .voting
        ) {
            VStack(spacing: 20) {
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
        }
        .navigationTitle("Voting")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            gameSessionStore: viewModel.gameSessionStore,
            onRepick: { viewModel.repickRoles() },
            onEndGame: { viewModel.endGame() }
        )
        .confirmDialog(
            isPresented: $viewModel.showConfirmDialog,
            title: "Confirm elimination",
            message: "Eliminate \(viewModel.selectedPlayerName)?",
            confirmTitle: "Eliminate"
        ) {
            viewModel.submitElimination()
        }
    }
}

#Preview {
    NavigationStack {
        VotingView(viewModel: VotingViewModel(dependencies: AppDependencies()))
    }
}
