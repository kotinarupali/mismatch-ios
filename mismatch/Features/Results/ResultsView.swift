import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: viewModel.isSessionComplete ? "Game Over" : "Eliminated",
            subtitle: viewModel.roundSummary,
            icon: viewModel.isSessionComplete ? "trophy.fill" : "person.crop.circle.badge.xmark",
            roomStyle: .reveal
        ) {
            VStack(spacing: 16) {
                OutcomeCard(title: "Eliminated", value: viewModel.eliminatedName, icon: "person.crop.circle.badge.xmark")
                OutcomeCard(title: "Role", value: viewModel.eliminatedRole, icon: "theatermasks.fill")
                OutcomeCard(title: "Word", value: viewModel.eliminatedWord, icon: "text.quote")

                if viewModel.isSessionComplete {
                    if let winner = viewModel.sessionWinnerText {
                        OutcomeCard(title: "Winner", value: winner, icon: "trophy.fill")
                    }

                    PrimaryButton(title: "Play Again") {
                        viewModel.playAgainTapped()
                    }

                    SecondaryButton(title: "New Game") {
                        viewModel.newGameTapped()
                    }
                } else {
                    PrimaryButton(title: "Continue Discussion") {
                        viewModel.continueTapped()
                    }

                    SecondaryButton(title: "End Game") {
                        viewModel.newGameTapped()
                    }
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ResultsView(viewModel: ResultsViewModel(dependencies: AppDependencies()))
    }
}
