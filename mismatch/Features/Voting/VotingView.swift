import SwiftUI

struct VotingView: View {
    @Bindable var viewModel: VotingViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Voting",
            subtitle: "Tap a player to eliminate."
        ) {
            VStack(spacing: 16) {
                PlayerGridView(
                    players: viewModel.activePlayers,
                    selectedPlayerId: viewModel.selectedPlayerId,
                    onSelect: { viewModel.selectPlayer($0) }
                )

                PrimaryButton(title: "Confirm Vote") {
                    viewModel.confirmVoteTapped()
                }
                .disabled(viewModel.selectedPlayerId == nil)
            }
        }
        .navigationTitle("Voting")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
