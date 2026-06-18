import SwiftUI

struct SessionSummaryView: View {
    @Bindable var viewModel: SessionSummaryViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Game Night Over",
            subtitle: viewModel.subtitle,
            icon: "trophy.fill",
            roomStyle: .reveal
        ) {
            VStack(spacing: 20) {
                if viewModel.showsGameOutcome {
                    sessionOutcomeHeader
                    GameFinalResultsSection(
                        insiderWord: viewModel.finalInsiderWord,
                        mismatchWord: viewModel.finalMismatchWord
                    )
                }

                if let leaderHeadline = viewModel.leaderHeadline {
                    Text(leaderHeadline)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.label)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                }

                if viewModel.hasScores {
                    SessionScoreboardView(
                        title: "Tonight's leaderboard",
                        rows: viewModel.scoreboardRows,
                        showsRoundPoints: false,
                        highlightTopRank: true
                    )
                } else {
                    noScoresCard
                }

                if viewModel.showsPartyPersonas {
                    SecondaryButton(title: "Party Personas") {
                        viewModel.openPartyPersonas()
                    }
                }

                PrimaryButton(title: viewModel.isRedistributing ? "Setting up…" : "Play Again") {
                    viewModel.playAgainTapped()
                }
                .disabled(viewModel.isRedistributing)

                SecondaryButton(title: "New Game Night") {
                    viewModel.newGameNightTapped()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showPartyPersonas) {
            GameNightPersonasSheet(
                cards: viewModel.personaCards,
                gamesPlayedCount: viewModel.gamesPlayedCount
            ) {
                // Stay on session summary after personas.
            }
        }
        .onAppear { viewModel.onAppear() }
    }

    private var sessionOutcomeHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ForEach(viewModel.winningRolesOrdered, id: \.self) { role in
                    RoleIconBadge(role: role, size: .extraLarge)
                }
            }

            if let headline = viewModel.winnerHeadline {
                Text(headline)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.winnerPlayerNames.isEmpty {
                Text(viewModel.winnerPlayerNames.joined(separator: " · "))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var noScoresCard: some View {
        Text("No points were scored this game night.")
            .font(AppTypography.body)
            .foregroundStyle(AppColor.secondaryLabel)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColor.cardBorder, lineWidth: 1)
            }
    }
}

#Preview {
    NavigationStack {
        SessionSummaryView(viewModel: SessionSummaryViewModel(dependencies: AppDependencies()))
    }
}
