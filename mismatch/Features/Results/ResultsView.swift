import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    var body: some View {
        ZStack {
            PlaceholderScreenLayout(
                title: viewModel.isSessionComplete ? "Game Over" : "Eliminated",
                subtitle: viewModel.roundSummary,
                icon: viewModel.isSessionComplete ? "trophy.fill" : "person.crop.circle.badge.xmark",
                roomStyle: .reveal
            ) {
                VStack(spacing: 16) {
                    if viewModel.isSessionComplete, viewModel.sessionOutcome != nil {
                        sessionOutcomeHeader
                    }

                    OutcomeCard(title: "Eliminated", value: viewModel.eliminatedName, icon: "person.crop.circle.badge.xmark")
                    OutcomeCard(title: "Role", value: viewModel.eliminatedRole, icon: "theatermasks.fill")
                    if viewModel.shouldShowEliminatedWord {
                        OutcomeCard(title: "Word", value: viewModel.eliminatedWord, icon: "text.quote")
                    }

                    if viewModel.isSessionComplete {
                        PrimaryButton(title: "Play Again") {
                            viewModel.playAgainTapped()
                        }

                        SecondaryButton(title: "Exit") {
                            viewModel.exitTapped()
                        }
                    } else {
                        PrimaryButton(title: "Continue Discussion") {
                            viewModel.continueTapped()
                        }

                        SecondaryButton(title: "Exit") {
                            viewModel.exitTapped()
                        }
                    }
                }
            }

            if viewModel.isSessionComplete, viewModel.sessionOutcome != nil {
                PartyOutcomeAnimation(insidersWon: viewModel.insidersWon)
                    .zIndex(1)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var sessionOutcomeHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.insidersWon ? "Insiders win!" : "Insiders lose!")
                .font(AppTypography.largeTitle)
                .foregroundStyle(viewModel.insidersWon ? AppColor.success : AppColor.accentSecondary)
                .multilineTextAlignment(.center)

            if let winner = viewModel.sessionWinnerText {
                Text(winner)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        ResultsView(viewModel: ResultsViewModel(dependencies: AppDependencies()))
    }
}
