import SwiftUI

struct PlayerGridView: View {
    let players: [PlayerSlot]
    let selectedPlayerId: UUID?
    let onSelect: (UUID) -> Void

    private let columns = [GridItem(.adaptive(minimum: 72))]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(players) { player in
                Button {
                    onSelect(player.id)
                } label: {
                    VStack(spacing: 8) {
                        AvatarView(
                            name: player.displayName,
                            color: player.avatarColor,
                            size: 56
                        )
                        .overlay {
                            if selectedPlayerId == player.id {
                                Circle()
                                    .strokeBorder(AppColor.accent, lineWidth: 3)
                            }
                        }

                        Text(player.isHost ? "You" : player.displayName)
                            .font(AppTypography.caption)
                            .lineLimit(1)
                            .foregroundStyle(AppColor.label)
                    }
                    .frame(minWidth: 72, minHeight: 88)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(player.isHost ? "You" : player.displayName)
                .accessibilityAddTraits(selectedPlayerId == player.id ? .isSelected : [])
            }
        }
    }
}
