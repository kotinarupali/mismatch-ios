import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            PartyRoomBackground(style: .home)

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            viewModel.openGameRules()
                        } label: {
                            homeTopButtonLabel(title: "How to Play", systemImage: "book.fill")
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            viewModel.openGameSettings()
                        } label: {
                            homeTopButtonLabel(title: "Settings", systemImage: "gearshape.fill")
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Game settings")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Spacer(minLength: 24)

                    VStack(spacing: 16) {
                        MismatchLogoView(size: 96)

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

                    Spacer(minLength: 28)

                    SecondaryButton(title: "Profiles") {
                        viewModel.openProfiles()
                    }
                    .padding(.horizontal, 24)

                    PrimaryButton(title: "Host a Game") {
                        viewModel.hostGameTapped()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
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
        .sheet(isPresented: $viewModel.showGameSettings) {
            HomeSettingsSheet(viewModel: viewModel)
        }
    }

    private func homeTopButtonLabel(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
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

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(dependencies: AppDependencies()))
    }
}
