import SwiftUI

struct PassThePhoneView: View {
    @Bindable var viewModel: PassThePhoneViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            icon: "iphone.and.arrow.forward",
            roomStyle: .distribution
        ) {
            if viewModel.awaitingHandoff {
                handoffContent
            } else if viewModel.canShowCardPick, let assignment = viewModel.currentAssignment {
                CardPickView(
                    cardCount: viewModel.faceDownCardCount,
                    showRoleOnCard: viewModel.showRoleOnCard,
                    assignment: assignment,
                    onComplete: { viewModel.cardCompleted() }
                )
                .id(viewModel.currentPlayerId)
            } else {
                Text("Waiting for role assignment…")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
        .navigationTitle("Roles")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var handoffContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundStyle(AppColor.heroGradient)
                .padding(.top, 8)

            Text("Only \(viewModel.currentPlayerDisplayName) should continue.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)

            PrimaryButton(title: "I'm \(viewModel.currentPlayerDisplayName) — Pick my card") {
                viewModel.readyToPickTapped()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        PassThePhoneView(viewModel: PassThePhoneViewModel(dependencies: AppDependencies()))
    }
}
