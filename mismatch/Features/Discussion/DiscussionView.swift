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
            VStack(spacing: 28) {
                TimerView(
                    timeLabel: viewModel.timerService.formattedTime,
                    totalSeconds: viewModel.timerDurationSeconds
                )

                PrimaryButton(title: "End Early") {
                    viewModel.endEarlyTapped()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

#Preview {
    NavigationStack {
        DiscussionView(viewModel: DiscussionViewModel(dependencies: AppDependencies()))
    }
}
