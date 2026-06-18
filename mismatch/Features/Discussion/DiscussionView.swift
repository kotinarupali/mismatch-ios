import SwiftUI

struct DiscussionView: View {
    @Bindable var viewModel: DiscussionViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Discussion",
            subtitle: "Find who doesn't know the secret word."
        ) {
            VStack(spacing: 24) {
                TimerView(timeLabel: viewModel.timerService.formattedTime)

                PrimaryButton(title: "End Early") {
                    viewModel.endEarlyTapped()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

#Preview {
    NavigationStack {
        DiscussionView(viewModel: DiscussionViewModel(dependencies: AppDependencies()))
    }
}
