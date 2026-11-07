import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel

    var body: some View {
        ZStack {
            PartyRoomBackground(style: .home)

            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HStack {
                            Button {
                                viewModel.openGameRules()
                            } label: {
                                homeTopButtonLabel(title: "How to Play", artwork: PartyArt.howToPlay)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button {
                                viewModel.openGameSettings()
                            } label: {
                                homeTopButtonLabel(title: "Settings", artwork: PartyArt.settings)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Game settings")
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                        VStack(spacing: 16) {
                            PartySticker(
                                name: PartyArt.appIcon,
                                size: PartyArt.appIconDisplaySize,
                                accessibilityLabel: "Sus Out"
                            )

                            Text("Sus Out")
                                .font(AppTypography.largeTitle)
                                .foregroundStyle(AppColor.label)

                            Text("Grab your friends, share a secret word,\nand spot the odd one out.")
                                .font(AppTypography.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AppColor.secondaryLabel)
                                .padding(.horizontal, 24)

                            HStack(spacing: 18) {
                                homeRoleChip(role: .insider, caption: "Knows it")
                                homeRoleChip(role: .mismatch, caption: "Wrong word")
                                homeRoleChip(role: .ghost, caption: "No word")
                            }
                            .padding(.top, 4)

                            // https://github.com/kotinarupali/mismatch-ios/issues/32
                            Button {
                                viewModel.openCustomPacks()
                            } label: {
                                homeTopButtonLabel(title: "Custom Packs", artwork: PartyArt.customPacks)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Custom packs")

                            if let stats = viewModel.wordPairStats {
                                VStack(spacing: 4) {
                                    Text("\(stats.remaining) fresh pairs left")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.label)
                                    Text("\(stats.used) played of \(stats.total)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColor.secondaryLabel)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(AppColor.card.opacity(0.85))
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule().strokeBorder(AppColor.cardBorder, lineWidth: 1)
                                }
                            }
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 28)

                        VStack(spacing: 12) {
                            SecondaryButton(title: "Profiles", artwork: PartyArt.profiles) {
                                viewModel.openProfiles()
                            }

                            PrimaryButton(title: "Start a party", artwork: PartyArt.host) {
                                viewModel.hostGameTapped()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                    .frame(minHeight: geo.size.height)
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
        .sheet(isPresented: $viewModel.showCustomPacks, onDismiss: {
            viewModel.refreshWordPairStats()
        }) {
            CustomPacksSheet(viewModel: viewModel.makeCustomPacksViewModel())
        }
    }

    private func homeTopButtonLabel(title: String, artwork: String) -> some View {
        HStack(spacing: 8) {
            PartySticker(name: artwork, size: 28)
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.label)
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(AppColor.card.opacity(0.85))
        .clipShape(Capsule())
        .overlay {
            Capsule().strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }

    private func homeRoleChip(role: Role, caption: String) -> some View {
        VStack(spacing: 6) {
            RoleIconBadge(role: role, size: .large)
            Text(role.displayName)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.label)
            Text(caption)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(role.displayName), \(caption)")
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel(dependencies: AppDependencies()))
    }
}
