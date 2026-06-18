import SwiftUI

struct ResultsView: View {
    @Bindable var viewModel: ResultsViewModel

    var body: some View {
        ZStack {
            if viewModel.isSessionComplete, viewModel.sessionOutcome != nil {
                PartyOutcomeAnimation(celebrationOnly: true)
            }

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

                    if viewModel.shouldShowFinalResults {
                        if viewModel.shouldShowFinalScoreboard {
                            FinalScoreboardView(rows: viewModel.finalScoreboardRows)
                        }

                        GameFinalResultsSection(
                            insiderWord: viewModel.finalInsiderWord,
                            mismatchWord: viewModel.finalMismatchWord
                        )
                    } else {
                        OutcomeCard(title: "Eliminated", value: viewModel.eliminatedName, icon: "person.crop.circle.badge.xmark")
                        OutcomeCard(title: "Role", value: viewModel.eliminatedRole, icon: "theatermasks.fill")
                        if viewModel.shouldShowEliminatedWord {
                            OutcomeCard(title: "Word", value: viewModel.eliminatedWord, icon: "text.quote")
                        }
                    }

                    if viewModel.shouldPromptGhostGuess {
                        ghostGuessSection
                    } else if let feedback = viewModel.ghostGuessFeedback, !viewModel.isSessionComplete {
                        Text(feedback)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.accentSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if viewModel.shouldPromptGhostGuess {
                        PrimaryButton(
                            title: "Submit Guess",
                            isEnabled: viewModel.canSubmitGhostGuess
                        ) {
                            viewModel.submitGhostGuessTapped()
                        }
                    } else if viewModel.isSessionComplete {
                        PrimaryButton(title: "Play Again") {
                            viewModel.playAgainTapped()
                        }
                    } else {
                        PrimaryButton(title: "Continue Discussion") {
                            viewModel.continueTapped()
                        }
                    }
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            gameSessionStore: viewModel.gameSessionStore,
            onRepick: { viewModel.playAgainTapped() },
            onEndGame: { viewModel.exitTapped() }
        )
    }

    private var ghostGuessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                RoleIconBadge(role: .ghost, size: .extraLarge)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Ghost's last guess")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.label)
                    Text("Guess the insider word — not the mismatch word.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            TextField("Type the word…", text: $viewModel.ghostGuess)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                }
                .foregroundStyle(AppColor.label)
                .onSubmit {
                    if viewModel.canSubmitGhostGuess {
                        viewModel.submitGhostGuessTapped()
                    }
                }

            if let feedback = viewModel.ghostGuessFeedback {
                Text(feedback)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accentSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.card.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
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

            Text(viewModel.winnerHeadline ?? "")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(winnerHeadlineColor)
                .multilineTextAlignment(.center)

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
        let roles = viewModel.winningRoles
        if roles.contains(.ghost), roles.contains(.mismatch) { return AppColor.accent }
        if roles.contains(.ghost) { return Color(red: 0.72, green: 0.55, blue: 1.0) }
        if roles.contains(.mismatch) { return AppColor.warning }
        return AppColor.success
    }
}

#Preview {
    NavigationStack {
        ResultsView(viewModel: ResultsViewModel(dependencies: AppDependencies()))
    }
}
