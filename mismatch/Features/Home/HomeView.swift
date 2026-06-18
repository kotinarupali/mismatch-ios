import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            PartyRoomBackground(style: .home)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppColor.heroGradient)
                            .frame(width: 88, height: 88)
                            .shadow(color: AppColor.accent.opacity(0.5), radius: 24, y: 12)

                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("Mismatch")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColor.label)

                    Text("Secret words. Suspicious faces.\nOne wrong answer.")
                        .font(AppTypography.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .padding(.horizontal, 24)

                    if let count = viewModel.wordPackPairCount {
                        Text("\(count) word pairs ready")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppColor.card.opacity(0.85))
                            .clipShape(Capsule())
                            .overlay {
                                Capsule().strokeBorder(AppColor.cardBorder, lineWidth: 1)
                            }
                    }
                }

                Spacer()

                PrimaryButton(title: "Host a Game") {
                    viewModel.hostGameTapped()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear { viewModel.onAppear() }
        .alert("How to Play", isPresented: $viewModel.showInlineRules) {
            Button("Let's go") { viewModel.dismissInlineRules() }
        } message: {
            Text("""
            • Most players share a secret word — one has a similar wrong word.
            • Discuss, then vote to eliminate who seems off.
            • Find the Mismatch before they blend in.
            """)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(dependencies: AppDependencies()))
    }
}
