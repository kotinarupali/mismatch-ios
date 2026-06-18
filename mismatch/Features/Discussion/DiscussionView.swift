import SwiftUI

struct DiscussionView: View {
    @Bindable var viewModel: DiscussionViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Discussion",
            subtitle: "Find who doesn't know the secret word.",
            icon: "bubble.left.and.bubble.right.fill",
            roomStyle: .discussion
        ) {
            VStack(spacing: 24) {
                if viewModel.timerEnabled {
                    TimerView(
                        timeLabel: viewModel.timerService.formattedTime,
                        totalSeconds: viewModel.timerDurationSeconds
                    )
                } else {
                    Text("Take your time — start voting when the group is ready.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }

                SecondaryButton(title: "Reveal Roles") {
                    viewModel.revealRolesTapped()
                }

                PrimaryButton(title: viewModel.timerEnabled ? "End Early" : "Start Voting") {
                    viewModel.startVotingTapped()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            onRepick: { viewModel.repickRoles() },
            onEndGame: { viewModel.endGame() },
            onRevealRoles: { viewModel.revealRolesTapped() }
        )
        .sheet(isPresented: $viewModel.showRolesReveal) {
            RolesRevealSheet(players: viewModel.playersForReveal)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

#Preview {
    NavigationStack {
        DiscussionView(viewModel: DiscussionViewModel(dependencies: AppDependencies()))
    }
}
