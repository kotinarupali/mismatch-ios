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

                if viewModel.showsLeaderboard {
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

                PrimaryButton(title: "Back to Home") {
                    viewModel.backToHomeTapped()
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
                viewModel.backToHomeTapped()
            }
        }
        .onAppear { viewModel.onAppear() }
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
