import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Reveal",
            subtitle: viewModel.outcomeText
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.eliminatedName)
                        .font(AppTypography.title)
                    Label(viewModel.eliminatedRole, systemImage: "person.fill.questionmark")
                        .font(AppTypography.body)
                    Text("Word: \(viewModel.eliminatedWord)")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
    }
}

#Preview {
    NavigationStack {
        ResultsView(viewModel: ResultsViewModel(dependencies: AppDependencies()))
    }
}
