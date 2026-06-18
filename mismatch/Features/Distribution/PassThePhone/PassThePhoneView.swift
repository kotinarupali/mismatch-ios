import SwiftUI

struct PassThePhoneView: View {
    @Bindable var viewModel: PassThePhoneViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: viewModel.title,
            subtitle: viewModel.subtitle
        ) {
            if let assignment = viewModel.currentAssignment {
                CardPickView(
                    showRoleOnCard: viewModel.showRoleOnCard,
                    assignment: assignment,
                    onComplete: { viewModel.cardCompleted() }
                )
            } else {
                Text("Waiting for role assignment…")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
        }
        .navigationTitle("Roles")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PassThePhoneView(viewModel: PassThePhoneViewModel(dependencies: AppDependencies()))
    }
}
