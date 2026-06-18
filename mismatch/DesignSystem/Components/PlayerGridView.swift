import SwiftUI

struct PlayerGridView: View {
    enum Style {
        case compact
        case tile
    }

    let players: [PlayerSlot]
    let selectedPlayerId: UUID?
    var style: Style = .compact
    var showEliminatedRoleBadges: Bool = false
    let onSelect: (UUID) -> Void

    private var columns: [GridItem] {
        switch style {
        case .compact:
            [GridItem(.adaptive(minimum: 88))]
        case .tile:
            [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        }
    }

    private var avatarSize: CGFloat {
        style == .tile ? 76 : 60
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: style == .tile ? 12 : 16) {
            ForEach(players) { player in
                playerCell(player)
            }
        }
    }

    @ViewBuilder
    private func playerCell(_ player: PlayerSlot) -> some View {
        let isEliminated = player.isEliminated
        let isSelected = selectedPlayerId == player.id && !isEliminated

        Button {
            guard !isEliminated else { return }
            onSelect(player.id)
        } label: {
            VStack(spacing: style == .tile ? 12 : 10) {
                AvatarView(
                    name: player.isHost ? "You" : player.displayName,
                    color: player.avatarColor,
                    size: avatarSize
                )
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(AppColor.accentSecondary, lineWidth: 3)
                            .frame(width: avatarSize + 8, height: avatarSize + 8)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if isEliminated, showEliminatedRoleBadges, let role = player.assignment?.role {
                        RoleIconBadge(role: role)
                            .offset(x: 4, y: 4)
                    }
                }

                Text(player.isHost ? "You" : player.displayName)
                    .font(style == .tile ? AppTypography.headline : AppTypography.caption)
                    .lineLimit(style == .tile ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(labelColor(isEliminated: isEliminated, isSelected: isSelected))
            }
            .frame(minWidth: style == .tile ? 0 : 88, minHeight: style == .tile ? 132 : 96)
            .frame(maxWidth: .infinity)
            .padding(.vertical, style == .tile ? 14 : 8)
            .padding(.horizontal, style == .tile ? 10 : 0)
            .background(cellBackground(isEliminated: isEliminated, isSelected: isSelected))
            .clipShape(RoundedRectangle(cornerRadius: style == .tile ? 18 : 16, style: .continuous))
            .overlay {
                if isEliminated {
                    RoundedRectangle(cornerRadius: style == .tile ? 18 : 16, style: .continuous)
                        .strokeBorder(AppColor.cardBorder.opacity(0.8), lineWidth: 1)
                }
            }
            .opacity(isEliminated ? 0.55 : 1)
            .grayscale(isEliminated ? 0.9 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isEliminated)
        .accessibilityLabel(accessibilityLabel(for: player))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func labelColor(isEliminated: Bool, isSelected: Bool) -> Color {
        if isEliminated { return AppColor.secondaryLabel.opacity(0.7) }
        return isSelected ? AppColor.label : AppColor.secondaryLabel
    }

    private func cellBackground(isEliminated: Bool, isSelected: Bool) -> Color {
        if isEliminated { return AppColor.card.opacity(0.45) }
        if style == .tile { return isSelected ? AppColor.card : AppColor.card.opacity(0.65) }
        return isSelected ? AppColor.card : Color.clear
    }

    private func accessibilityLabel(for player: PlayerSlot) -> String {
        let name = player.isHost ? "You" : player.displayName
        guard player.isEliminated, let role = player.assignment?.role else { return name }
        return "\(name), eliminated, \(role.displayName)"
    }
}

struct RoleIconBadge: View {
    let role: Role

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(badgeColor)
            .clipShape(Circle())
            .overlay {
                Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1)
            }
            .accessibilityLabel(role.displayName)
    }

    private var iconName: String {
        switch role {
        case .insider: "checkmark"
        case .mismatch: "exclamationmark"
        case .ghost: "questionmark"
        }
    }

    private var badgeColor: Color {
        switch role {
        case .insider: .green
        case .mismatch: .orange
        case .ghost: .purple
        }
    }
}
