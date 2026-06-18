import SwiftUI

struct PlayerGridView: View {
    let players: [PlayerSlot]
    let selectedPlayerId: UUID?
    let onSelect: (UUID) -> Void

    private let columns = [GridItem(.adaptive(minimum: 88))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(players) { player in
                Button {
                    onSelect(player.id)
                } label: {
                    VStack(spacing: 10) {
                        AvatarView(name: player.displayName, color: player.avatarColor, size: 60)
                            .overlay {
                                if selectedPlayerId == player.id {
                                    Circle()
                                        .strokeBorder(AppColor.accentSecondary, lineWidth: 3)
                                        .frame(width: 68, height: 68)
                                }
                            }

                        Text(player.isHost ? "You" : player.displayName)
                            .font(AppTypography.caption)
                            .lineLimit(1)
                            .foregroundStyle(
                                selectedPlayerId == player.id ? AppColor.label : AppColor.secondaryLabel
                            )
                    }
                    .frame(minWidth: 88, minHeight: 96)
                    .padding(.vertical, 8)
                    .background(
                        selectedPlayerId == player.id ? AppColor.card : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(player.isHost ? "You" : player.displayName)
                .accessibilityAddTraits(selectedPlayerId == player.id ? .isSelected : [])
            }
        }
    }
}
