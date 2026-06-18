import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Mismatch",
            subtitle: "Private role cards for big groups."
        ) {
            VStack(spacing: 16) {
                if let count = viewModel.wordPackPairCount {
                    Text("\(count) word pairs loaded")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }

                PrimaryButton(title: "Host Game") {
                    viewModel.hostGameTapped()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
        .alert("How to Play", isPresented: $viewModel.showInlineRules) {
            Button("Got it") { viewModel.dismissInlineRules() }
        } message: {
            Text("""
            • Most players share a secret word — one player has a similar wrong word.
            • Discuss and vote to eliminate the odd one out.
            • Insiders win if they eliminate a Mismatch or Ghost.
            """)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(dependencies: AppDependencies()))
    }
}
