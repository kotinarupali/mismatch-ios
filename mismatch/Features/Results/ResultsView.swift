import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Reveal",
            subtitle: viewModel.outcomeText,
            icon: "sparkles",
            roomStyle: .reveal
        ) {
            VStack(spacing: 16) {
                OutcomeCard(title: "Eliminated", value: viewModel.eliminatedName, icon: "person.crop.circle.badge.xmark")
                OutcomeCard(title: "Role", value: viewModel.eliminatedRole, icon: "theatermasks.fill")
                OutcomeCard(title: "Word", value: viewModel.eliminatedWord, icon: "text.quote")

                PrimaryButton(title: "Play Again") {
                    viewModel.playAgainTapped()
                }

                SecondaryButton(title: "New Game") {
                    viewModel.newGameTapped()
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
