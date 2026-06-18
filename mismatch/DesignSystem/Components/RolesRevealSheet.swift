import SwiftUI

struct RolesRevealSheet: View {
    let players: [PlayerSlot]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        Text("Host only — don't show the group.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(players) { player in
                            RoleRevealRow(player: player)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("All Roles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct RoleRevealRow: View {
    let player: PlayerSlot

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(
                name: player.isHost ? "You" : player.displayName,
                color: player.avatarColor,
                size: 44
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(player.isHost ? "You" : player.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)

                if let assignment = player.assignment {
                    HStack(spacing: 8) {
                        RoleBadgeView(role: assignment.role)
                        Text(wordLabel(for: assignment))
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
                } else {
                    Text("No role assigned")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }

    private func wordLabel(for assignment: RoleAssignment) -> String {
        if let word = assignment.word {
            return word
        }
        if let hint = assignment.categoryHint {
            return "Hint: \(hint)"
        }
        return "No word"
    }
}
