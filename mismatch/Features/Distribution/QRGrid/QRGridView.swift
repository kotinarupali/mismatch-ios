import SwiftUI

struct QRGridView: View {
    @Bindable var viewModel: QRGridViewModel
    @State private var showMyCard = false

    var body: some View {
        PlaceholderScreenLayout(
            title: "QR Grid",
            subtitle: viewModel.statusMessage
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
        .background(AppColor.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
