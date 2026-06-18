import SwiftUI

struct GameFinalResultsSection: View {
    let insiderWord: String
    let mismatchWord: String
    let players: [PlayerRoleReveal]
    var winningRoles: Set<Role> = []

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                OutcomeCard(title: "Insider word", value: insiderWord, icon: "checkmark.seal.fill")
                OutcomeCard(title: "Mismatch word", value: mismatchWord, icon: "xmark.seal.fill")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Everyone's roles")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    ForEach(players) { player in
                        playerRow(player)
                    }
                }
            }
            .padding(14)
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(AppColor.cardBorder, lineWidth: 1)
            }
        }
    }

    private func playerRow(_ player: PlayerRoleReveal) -> some View {
        let isWinner = winningRoles.contains(player.role)

        return HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                AvatarView(name: player.displayName, color: player.avatarColor, size: 40)

                if isWinner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColor.warning)
                        .shadow(color: AppColor.warning.opacity(0.45), radius: 4, y: 1)
                        .offset(x: 6, y: -7)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                    .lineLimit(1)

                if player.isEliminated {
                    Text("Eliminated")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                } else if isWinner {
                    Text("Winner")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.warning)
                }
            }

            Spacer(minLength: 8)

            RoleIconBadge(role: player.role, size: .medium)
                .frame(width: 52, height: 52)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(rowBackground(isWinner: isWinner))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            if isWinner {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColor.warning.opacity(0.45), lineWidth: 1.5)
            }
        }
        .accessibilityLabel(accessibilityLabel(for: player, isWinner: isWinner))
    }

    private func rowBackground(isWinner: Bool) -> Color {
        if isWinner {
            AppColor.warning.opacity(0.12)
        } else {
            AppColor.backgroundElevated.opacity(0.85)
        }
    }

    private func accessibilityLabel(for player: PlayerRoleReveal, isWinner: Bool) -> String {
        var label = "\(player.displayName), \(player.role.displayName)"
        if isWinner { label += ", winner" }
        if player.isEliminated { label += ", eliminated" }
        return label
    }
}
