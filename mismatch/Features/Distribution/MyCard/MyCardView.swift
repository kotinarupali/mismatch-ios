import SwiftUI

struct MyCardView: View {
    @Bindable var viewModel: MyCardViewModel
    @Bindable private var sessionStore: GameSessionStore
    @Environment(\.dismiss) private var dismiss

    init(viewModel: MyCardViewModel) {
        self.viewModel = viewModel
        _sessionStore = Bindable(viewModel.dependencies.gameSessionStore)
    }

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
                            insiderWord: viewModel.insiderWord,
                            claimedCards: sessionStore.claimedCards(),
                            lockedCardIndex: viewModel.lockedCardIndex,
                            canGhostRoleSwap: viewModel.canGhostRoleSwap,
                            onGhostRoleSwap: { viewModel.swapGhostRole() },
                            onCardSeen: { cardIndex in
                                viewModel.hostSawCard(cardIndex: cardIndex)
                            },
                            onComplete: { cardIndex, attemptedGhostRoleSwap in
                                viewModel.markOpened(
                                    cardIndex: cardIndex,
                                    attemptedGhostRoleSwap: attemptedGhostRoleSwap
                                )
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
            .onAppear {
                viewModel.startCloudClaimRefresh()
                if let index = viewModel.lockedCardIndex {
                    viewModel.hostSawCard(cardIndex: index)
                }
            }
            .onDisappear {
                viewModel.stopCloudClaimRefresh()
            }
        }
        .preferredColorScheme(.dark)
    }
}
