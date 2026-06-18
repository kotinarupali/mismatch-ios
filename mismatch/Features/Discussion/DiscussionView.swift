import SwiftUI

struct DiscussionView: View {
    @Bindable var viewModel: DiscussionViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Discuss & Vote",
            subtitle: viewModel.cloudGuestVotingEnabled
                ? "Talk it out. Guests vote on their phones; you confirm the elimination."
                : "Talk it out, then tap a player to eliminate.",
            icon: "bubble.left.and.bubble.right.fill",
            roomStyle: .discussion
        ) {
            VStack(spacing: 20) {
                discussionStatusBar

                if viewModel.timerEnabled {
                    TimerView(
                        timeLabel: viewModel.timerService.formattedTime,
                        totalSeconds: viewModel.timerDurationSeconds
                    )
                }

                PlayerGridView(
                    players: viewModel.displayPlayers,
                    selectedPlayerId: viewModel.selectedPlayerId,
                    style: .tile,
                    showEliminatedRoleBadges: true,
                    discussionStarterId: viewModel.discussionStarterId,
                    voteCounts: viewModel.guestVoteTallies,
                    showsVoteCounts: viewModel.cloudGuestVotingEnabled,
                    onSelect: { viewModel.selectPlayer($0) }
                )

                if viewModel.showsGuestVoteTallies {
                    Text("Numbers show guest votes from phones.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if viewModel.showsRevotePrompt, let tiedNames = viewModel.tiedPlayerNamesLabel,
                   let tie = viewModel.guestVoteTie {
                    revotePromptCard(tiedNames: tiedNames, voteCount: tie.voteCount)
                }

                PrimaryButton(
                    title: "Confirm Vote",
                    isEnabled: viewModel.canConfirmVote
                ) {
                    viewModel.confirmVoteTapped()
                }

                SecondaryButton(title: "End game — no consensus") {
                    viewModel.noConsensusEndTapped()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Discuss & Vote")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            gameSessionStore: viewModel.gameSessionStore,
            onRepick: { viewModel.repickRoles() },
            onEndSession: { viewModel.endSessionTapped() },
            onCheckPlayerRole: { viewModel.checkPlayerRoleTapped() }
        )
        .sheet(isPresented: $viewModel.showPlayerRolePicker) {
            PlayerRolePickerSheet(players: viewModel.playersWithPickedCards) { player in
                viewModel.selectPlayerForRoleCheck(player)
            }
        }
        .sheet(item: $viewModel.playerToReveal) { player in
            PlayerRoleRevealSheet(player: player)
        }
        .confirmDialog(
            isPresented: $viewModel.showConfirmDialog,
            title: "Confirm elimination",
            message: "Eliminate \(viewModel.selectedPlayerName)?",
            confirmTitle: "Eliminate"
        ) {
            viewModel.submitElimination()
        }
        .confirmDialog(
            isPresented: $viewModel.showNoConsensusConfirmDialog,
            title: "End game on deadlock?",
            message: viewModel.noConsensusConfirmMessage,
            confirmTitle: "End Game"
        ) {
            viewModel.confirmNoConsensusEnd()
        }
        .alert(
            "Can't end yet",
            isPresented: $viewModel.showNoConsensusUnavailableAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.noConsensusConfirmMessage)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    @ViewBuilder
    private func revotePromptCard(tiedNames: String, voteCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColor.warning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tie vote")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColor.label)
                    Text("\(tiedNames) each have \(voteCount) vote\(voteCount == 1 ? "" : "s").")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SecondaryButton(title: viewModel.isStartingRevote ? "Starting revote…" : "Start Revote") {
                viewModel.startRevoteTapped()
            }
            .disabled(viewModel.isStartingRevote)

            if viewModel.noConsensusOutcome != nil {
                SecondaryButton(title: "End game — no consensus") {
                    viewModel.noConsensusEndTapped()
                }
            }

            Text("Guests vote again on their phones. Tied players can't be chosen. Or pick someone below to break the tie.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.warning.opacity(0.45), lineWidth: 1)
        }
    }

    @ViewBuilder
    private var discussionStatusBar: some View {
        HStack(alignment: .center, spacing: 12) {
            if let starterName = viewModel.discussionStarterName {
                HStack(spacing: 10) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(AppColor.warning)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(starterName) starts")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColor.label)
                            .lineLimit(1)
                        Text("Go clockwise")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            OutsiderCountsBanner(
                mismatchCount: viewModel.remainingMismatchCount,
                ghostCount: viewModel.remainingGhostCount,
                countSuffix: "left",
                style: .compact,
                showsGhostCount: viewModel.ghostEnabled
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        DiscussionView(viewModel: DiscussionViewModel(dependencies: AppDependencies()))
    }
}
