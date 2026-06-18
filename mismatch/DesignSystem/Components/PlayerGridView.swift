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
    var discussionStarterId: UUID?
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
        let isDiscussionStarter = discussionStarterId == player.id && !isEliminated
        let eliminatedRole = roleBadge(for: player)

        Button {
            guard !isEliminated else { return }
            onSelect(player.id)
        } label: {
            VStack(spacing: style == .tile ? 10 : 10) {
                if isDiscussionStarter {
                    discussionStarterBadge
                }

                AvatarView(
                    name: player.isHost ? "You" : player.displayName,
                    color: player.avatarColor,
                    size: avatarSize
                )
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(AppColor.accent, lineWidth: 3.5)
                            .frame(width: avatarSize + 10, height: avatarSize + 10)
                    }
                }
                .overlay {
                    if isEliminated, let role = eliminatedRole {
                        RoleIconBadge(role: role, size: eliminatedBadgeSize(for: role))
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
                if isSelected {
                    RoundedRectangle(cornerRadius: style == .tile ? 18 : 16, style: .continuous)
                        .strokeBorder(AppColor.accent.opacity(0.95), lineWidth: 2.5)
                } else if isDiscussionStarter {
                    RoundedRectangle(cornerRadius: style == .tile ? 18 : 16, style: .continuous)
                        .strokeBorder(AppColor.warning.opacity(0.85), lineWidth: 2)
                } else if isEliminated {
                    RoundedRectangle(cornerRadius: style == .tile ? 18 : 16, style: .continuous)
                        .strokeBorder(AppColor.cardBorder.opacity(0.8), lineWidth: 1)
                }
            }
            .shadow(
                color: isSelected ? AppColor.accent.opacity(0.35) : .clear,
                radius: isSelected ? 10 : 0,
                y: isSelected ? 3 : 0
            )
            .scaleEffect(isSelected && style == .tile ? 1.02 : 1)
            .animation(.easeOut(duration: 0.18), value: isSelected)
            .opacity(isEliminated ? 0.55 : 1)
            .grayscale(isEliminated ? 0.9 : 0)
        }
        .buttonStyle(.plain)
        .disabled(isEliminated)
        .accessibilityLabel(accessibilityLabel(for: player))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var discussionStarterBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 18, weight: .bold))
            Text("Starts")
                .font(AppTypography.headline)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(AppColor.warning)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    private func roleBadge(for player: PlayerSlot) -> Role? {
        guard player.isEliminated, showEliminatedRoleBadges, let role = player.assignment?.role else {
            return nil
        }
        return role
    }

    private func eliminatedBadgeSize(for role: Role) -> RoleIconBadge.Size {
        switch style {
        case .tile:
            role == .insider ? .hero : .extraLarge
        case .compact:
            role == .insider ? .extraLarge : .large
        }
    }

    private func labelColor(isEliminated: Bool, isSelected: Bool) -> Color {
        if isEliminated { return AppColor.secondaryLabel.opacity(0.7) }
        return isSelected ? AppColor.label : AppColor.secondaryLabel
    }

    private func cellBackground(isEliminated: Bool, isSelected: Bool) -> some View {
        Group {
            if isEliminated {
                AppColor.card.opacity(0.45)
            } else if isSelected {
                ZStack {
                    AppColor.cardSelected
                    AppColor.accent.opacity(0.12)
                }
            } else if style == .tile {
                AppColor.card.opacity(0.5)
            } else {
                Color.clear
            }
        }
    }

    private func accessibilityLabel(for player: PlayerSlot) -> String {
        let name = player.isHost ? "You" : player.displayName
        if player.isEliminated, let role = roleBadge(for: player) {
            return "\(name), eliminated, \(role.displayName)"
        }
        if discussionStarterId == player.id, !player.isEliminated {
            return "\(name), starts discussion, first in circle"
        }
        return name
    }
}
