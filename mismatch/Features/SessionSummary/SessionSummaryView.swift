import SwiftUI

struct SessionSummaryView: View {
    @Bindable var viewModel: SessionSummaryViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: layoutTitle,
            subtitle: layoutSubtitle,
            icon: layoutIcon,
            showsBrandLogo: viewModel.phase == .personas,
            roomStyle: .reveal
        ) {
            VStack(spacing: 20) {
                switch viewModel.phase {
                case .scoreboard:
                    scoreboardContent
                    scoreboardActions
                case .personas:
                    GameNightPersonasList(
                        cards: viewModel.personaCards,
                        gamesPlayedCount: viewModel.gamesPlayedCount,
                        showsIntro: false
                    )
                    personasActions
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Session Summary")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
    }

    private var layoutTitle: String {
        viewModel.phase == .personas ? "Party Personas" : "Game Night Over"
    }

    private var layoutSubtitle: String {
        viewModel.phase == .personas
            ? "How everyone showed up tonight"
            : viewModel.subtitle
    }

    private var layoutIcon: String? {
        viewModel.phase == .personas ? nil : "trophy.fill"
    }

    @ViewBuilder
    private var scoreboardContent: some View {
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

        if viewModel.showsDetailedScoreboard {
            FinalScoreboardView(
                title: "Tonight's leaderboard",
                rows: viewModel.finalScoreboardRows
            )
        } else if viewModel.showsLeaderboard {
            SessionScoreboardView(
                title: "Tonight's leaderboard",
                rows: viewModel.scoreboardRows,
                showsRoundPoints: true,
                showsRoundPointsBubble: true,
                highlightTopRank: true
            )
        } else {
            noScoresCard
        }
    }

    private var scoreboardActions: some View {
        VStack(spacing: 12) {
            SecondaryButton(title: "Party Personas") {
                viewModel.showPersonasTapped()
            }

            PrimaryButton(title: "Back to Home") {
                viewModel.backToHomeTapped()
            }
        }
    }

    private var personasActions: some View {
        VStack(spacing: 12) {
            SecondaryButton(title: "Back to Scores") {
                viewModel.backToScoresTapped()
            }

            PrimaryButton(title: "Back to Home") {
                viewModel.backToHomeTapped()
            }
        }
    }

    private var sessionOutcomeHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColor.warning)
                .shadow(color: AppColor.warning.opacity(0.5), radius: 6, y: 2)

            HStack(spacing: 10) {
                ForEach(viewModel.winningRolesOrdered, id: \.self) { role in
                    RoleIconBadge(role: role, size: .extraLarge)
                }
            }

            if let headline = viewModel.winnerHeadline {
                Text(headline)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(winnerHeadlineColor)
                    .multilineTextAlignment(.center)
            }

            if !viewModel.winnerPlayerNames.isEmpty {
                Text(viewModel.winnerPlayerNames.joined(separator: " · "))
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.label)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    private var winnerHeadlineColor: Color {
        guard let outcome = viewModel.sessionOutcome else { return AppColor.label }
        let roles = outcome.winningRoles(
            allianceEnabled: viewModel.mismatchGhostAllianceEnabled
        )
        if roles.contains(.ghost), roles.contains(.mismatch) { return AppColor.accent }
        if roles.contains(.ghost) { return Color(red: 0.72, green: 0.55, blue: 1.0) }
        if roles.contains(.mismatch) { return AppColor.warning }
        return AppColor.success
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
