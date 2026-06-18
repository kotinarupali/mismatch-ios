import SwiftUI

struct MyCardView: View {
    @Bindable var viewModel: MyCardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if let assignment = viewModel.assignment {
                    CardPickView(
                        showRoleOnCard: viewModel.showRoleOnCard,
                        assignment: assignment,
                        onComplete: {
                            viewModel.markOpened()
                            dismiss()
                        }
                    )
                    .padding()
                } else {
                    Text("No card assigned.")
                        .foregroundStyle(AppColor.secondaryLabel)
                }
            }
            .navigationTitle("My Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
