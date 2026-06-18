import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            PartyRoomBackground(style: .home)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        viewModel.openGameRules()
                    } label: {
                        Label("How to Play", systemImage: "book.fill")
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
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

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

                    if let stats = viewModel.wordPairStats {
                        VStack(spacing: 6) {
                            Text("\(stats.used) played · \(stats.remaining) remaining")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.label)
                            Text("of \(stats.total) word pairs")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppColor.card.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().strokeBorder(AppColor.cardBorder, lineWidth: 1)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    SecondaryButton(title: "How to Play") {
                        viewModel.openGameRules()
                    }

                    PrimaryButton(title: "Host a Game") {
                        viewModel.hostGameTapped()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onAppear { viewModel.onAppear() }
        .sheet(isPresented: $viewModel.showGameRules, onDismiss: {
            viewModel.dismissGameRules()
        }) {
            GameRulesSheet()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(dependencies: AppDependencies()))
    }
}
