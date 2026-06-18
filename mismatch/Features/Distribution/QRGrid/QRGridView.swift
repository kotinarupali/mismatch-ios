import SwiftUI

struct QRGridView: View {
    @Bindable var viewModel: QRGridViewModel
    @State private var showMyCard = false

    var body: some View {
        PlaceholderScreenLayout(
            title: "QR Grid",
            subtitle: viewModel.statusMessage,
            icon: "qrcode.viewfinder",
            roomStyle: .distribution
        ) {
            VStack(spacing: 16) {
                if viewModel.serverFailed {
                    Text("Could not start local card server. Use pass-the-phone instead.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.red)

                    PrimaryButton(title: "Switch to Pass the Phone") {
                        viewModel.fallbackToPassThePhone()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.playerRows) { row in
                                QRGridCell(row: row, onCopy: { viewModel.copyLink(for: row.id) })
                            }
                        }
                    }
                    .frame(maxHeight: 400)

                    if viewModel.hostIsPlaying {
                        SecondaryButton(title: "View My Card") {
                            showMyCard = true
                        }
                    }

                    PrimaryButton(title: "Start Discussion") {
                        viewModel.startDiscussionTapped()
                    }
                }
            }
        }
        .navigationTitle("QR Codes")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .hostGameMenu(
            onRepick: { viewModel.repickRoles() },
            onEndGame: { viewModel.endGame() },
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
}

private struct QRGridCell: View {
    let row: QRGridViewModel.PlayerRow
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(row.displayName)
                    .font(AppTypography.headline)
                if let url = row.cardURL {
                    Text(url)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .lineLimit(2)
                    Button("Copy Link", action: onCopy)
                        .font(AppTypography.caption)
                }
            }
            Spacer()
            if let image = row.qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .accessibilityLabel("QR code for \(row.displayName)")
            }
        }
        .padding()
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}
