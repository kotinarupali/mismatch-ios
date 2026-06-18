import SwiftUI

struct MyCardView: View {
    @Bindable var viewModel: MyCardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PartyRoomBackground(style: .distribution)

                VStack {
                    if let assignment = viewModel.assignment {
                        CardPickView(
                            cardCount: viewModel.faceDownCardCount,
                            showRoleOnCard: viewModel.showRoleOnCard,
                            assignment: assignment,
                            onComplete: { _ in
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
            }
            .navigationTitle("My Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.85), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
