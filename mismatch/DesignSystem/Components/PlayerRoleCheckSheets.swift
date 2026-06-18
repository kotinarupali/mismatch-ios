import SwiftUI

struct PlayerRolePickerSheet: View {
    let players: [PlayerSlot]
    let onSelect: (PlayerSlot) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                if players.isEmpty {
                    Text("No one has picked a card yet.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.secondaryLabel)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Host only — pick one player to check their role.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(players) { player in
                                Button {
                                    onSelect(player)
                                    dismiss()
                                } label: {
                                    PlayerRolePickerRow(player: player)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Check Role")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct PlayerRoleRevealSheet: View {
    let player: PlayerSlot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Host only — don't show the group.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)

                    AvatarView(
                        name: player.isHost ? "You" : player.displayName,
                        color: player.avatarColor,
                        size: 72
                    )

                    Text(player.isHost ? "You" : player.displayName)
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColor.label)

                    if let assignment = player.assignment {
                        RoleBadgeView(role: assignment.role)
                        Text(wordLabel(for: assignment))
                            .font(AppTypography.title)
                            .foregroundStyle(AppColor.label)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No role assigned")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Player Role")
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

private struct PlayerRolePickerRow: View {
    let player: PlayerSlot

    var body: some View {
        HStack(spacing: 14) {
            AvatarView(
                name: player.isHost ? "You" : player.displayName,
                color: player.avatarColor,
                size: 44
            )
            Text(player.isHost ? "You" : player.displayName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColor.secondaryLabel)
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
