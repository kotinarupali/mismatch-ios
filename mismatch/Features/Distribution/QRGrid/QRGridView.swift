import SwiftUI

struct QRGridView: View {
    @Bindable var viewModel: QRGridViewModel
    @Bindable private var sessionStore: GameSessionStore
    @State private var showMyCard = false

    init(viewModel: QRGridViewModel) {
        self.viewModel = viewModel
        _sessionStore = Bindable(viewModel.dependencies.gameSessionStore)
    }

    var body: some View {
        PlaceholderScreenLayout(
            title: "Scan to Join",
            subtitle: viewModel.statusMessage,
            showsBrandLogo: true,
            roomStyle: .distribution
        ) {
            VStack(spacing: 16) {
                if viewModel.serverFailed {
                    Text(viewModel.serverFailureMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(.red)

                    PrimaryButton(title: "Switch to Pass the Phone") {
                        viewModel.fallbackToPassThePhone()
                    }
                } else {
                    sharedQRCodeSection

                    playerStatusSection

                    if viewModel.hostIsPlaying {
                        SecondaryButton(title: "View My Card") {
                            showMyCard = true
                        }
                    }

                    PrimaryButton(
                        title: "Start Discussion",
                        isEnabled: viewModel.canStartDiscussion
                    ) {
                        viewModel.startDiscussionTapped()
                    }
                }
            }
        }
        .navigationTitle("Join Game")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            gameSessionStore: sessionStore,
            onRepick: { viewModel.repickRoles() },
            onEndSession: { viewModel.endSessionTapped() },
            onCheckPlayerRole: { viewModel.checkPlayerRoleTapped() }
        )
        .sheet(isPresented: $viewModel.showPlayerRolePicker) {
            PlayerRolePickerSheet(players: viewModel.playersWithPickedCards) { player in
                viewModel.selectPlayerForRoleCheck(player)
            }
        }
        .sheet(item: $viewModel.playerToReveal) { player in
            PlayerRoleRevealSheet(player: player)
        }
        .sheet(isPresented: $showMyCard) {
            MyCardView(viewModel: MyCardViewModel(dependencies: viewModel.dependencies))
        }
    }

    private var sharedQRCodeSection: some View {
        VStack(spacing: 14) {
            Text("One QR for everyone")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)

            Text("The first phone to tap a name keeps that card. Give it back here if the wrong phone took it.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)

            requirementsSection

            Text(viewModel.joinInstructions)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.accent)
                .multilineTextAlignment(.center)

            if let image = viewModel.qrImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppColor.heroGradient)
                        .frame(width: 252, height: 252)
                        .shadow(color: BrandPalette.ghostMid.opacity(0.35), radius: 16, y: 8)

                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .accessibilityLabel("Shared game QR code")
            }

            if let url = viewModel.sharedJoinURL {
                Text(url)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .textSelection(.enabled)

                HStack(spacing: 12) {
                    SecondaryButton(title: "Copy Link") {
                        viewModel.copySharedLink()
                    }

                    if let shareURL = URL(string: url) {
                        ShareLink(item: shareURL) {
                            Text("Send Link")
                                .font(AppTypography.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColor.backgroundElevated)
                                .foregroundStyle(AppColor.label)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }

    private var requirementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requirements")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
            Text(viewModel.requirementsText)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4)
    }

    private var playerStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick progress")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)

            if viewModel.hostIsPlaying {
                pickStatusRow(name: "You (host)", hasPicked: viewModel.hostHasPicked)
            }

            if let giveBackError = viewModel.giveBackError {
                Text(giveBackError)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }

            ForEach(sessionStore.currentSession?.players.filter { !$0.isHost } ?? []) { player in
                pickStatusRow(player: player)
            }
        }
        .confirmationDialog(
            giveBackTitle,
            isPresented: Binding(
                get: { viewModel.playerPendingGiveBack != nil },
                set: { if !$0 { viewModel.playerPendingGiveBack = nil } }
            ),
            titleVisibility: .visible,
            presenting: viewModel.playerPendingGiveBack
        ) { player in
            Button("Give back", role: .destructive) {
                viewModel.giveBack(player)
            }
            Button("Cancel", role: .cancel) {
                viewModel.playerPendingGiveBack = nil
            }
        } message: { player in
            Text("\(player.displayName)'s phone will lose the card. They can tap their name again.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }

    private var giveBackTitle: String {
        let name = viewModel.playerPendingGiveBack?.displayName ?? "This player"
        return "Give \(name)'s card back?"
    }

    private func pickStatusRow(name: String, hasPicked: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: hasPicked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(hasPicked ? AppColor.success : AppColor.secondaryLabel)
            Text(name)
                .font(AppTypography.body)
                .foregroundStyle(hasPicked ? AppColor.label : AppColor.secondaryLabel)
            Spacer()
            Text(hasPicked ? "Picked" : "Waiting")
                .font(AppTypography.caption)
                .foregroundStyle(hasPicked ? AppColor.success : AppColor.secondaryLabel)
        }
    }

    private func pickStatusRow(player: PlayerSlot) -> some View {
        let held = viewModel.nameIsHeld(player.id)
        let status = player.hasOpenedCard ? "Picked" : (held ? "On a phone" : "Waiting")
        let active = player.hasOpenedCard || held
        return HStack(spacing: 10) {
            Image(systemName: player.hasOpenedCard ? "checkmark.circle.fill" : (held ? "iphone" : "circle"))
                .foregroundStyle(active ? AppColor.success : AppColor.secondaryLabel)
            Text(player.displayName)
                .font(AppTypography.body)
                .foregroundStyle(active ? AppColor.label : AppColor.secondaryLabel)
            Spacer()
            if held || player.hasOpenedCard {
                Button("Give back") {
                    viewModel.playerPendingGiveBack = player
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.accent)
            }
            Text(status)
                .font(AppTypography.caption)
                .foregroundStyle(active ? AppColor.success : AppColor.secondaryLabel)
        }
    }
}

#Preview {
    NavigationStack {
        QRGridView(viewModel: QRGridViewModel(dependencies: AppDependencies()))
    }
}
