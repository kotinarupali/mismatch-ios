import SwiftUI

struct GameRulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        introSection
                        rolesSection
                        setupSection
                        discussionSection
                        winningSection
                        tipsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("How to Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var introSection: some View {
        GameRuleSection(
            title: "The idea",
            icon: "lightbulb.fill",
            text: """
            Most players share one secret word. A few players are outsiders with a wrong word — or no word at all. \
            Talk, bluff, and vote to eliminate whoever seems suspicious before they blend in.
            """
        )
    }

    private var rolesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            GameRuleSectionHeader(title: "Roles", icon: "person.3.fill")

            roleRow(
                role: .insider,
                detail: "Gets the real secret word. Work together to spot and eliminate outsiders."
            )
            roleRow(
                role: .mismatch,
                detail: "Gets a similar but wrong word. Stay hidden and survive the votes."
            )
            roleRow(
                role: .ghost,
                detail: "Gets no word (optional role). Bluff from the conversation and survive."
            )
        }
    }

    private var setupSection: some View {
        GameRuleSection(
            title: "Setup",
            icon: "person.crop.circle.badge.plus",
            text: """
            1. Host adds players and arranges seating in circle order.
            2. Turn on Ghost or alliance rules if you want a wilder game.
            3. Tap Distribute Roles — everyone picks a card (pass-the-phone) or scans a QR code.
            4. Keep your role private. Only reveal what you choose during discussion.
            """
        )
    }

    private var discussionSection: some View {
        GameRuleSection(
            title: "Discuss & vote",
            icon: "bubble.left.and.bubble.right.fill",
            text: """
            1. A random player starts each discussion round.
            2. Give clues about your word — without saying it outright.
            3. When ready, tap a player and Confirm Vote to eliminate them.
            4. Their role is revealed. Eliminated players stay on the board but can't be voted again.
            """
        )
    }

    private var winningSection: some View {
        GameRuleSection(
            title: "Winning",
            icon: "trophy.fill",
            text: """
            Insiders win when every Mismatch (and Ghost, if enabled) has been eliminated.

            Mismatch wins if all Insiders are eliminated while a Mismatch is still in the game.

            Ghost wins if all Insiders are eliminated, no Mismatch remains, and a Ghost is still in the game.

            With Mismatch & Ghost alliance enabled, outsiders share a team win when Insiders are eliminated.
            """
        )
    }

    private var tipsSection: some View {
        GameRuleSection(
            title: "Tips",
            icon: "sparkles",
            text: """
            • Need at least 3 players to start.
            • Ghost is added automatically at 4+ players — turn it off in Rules if you want a simpler game.
            • The host can check any player's role mid-game from the menu.
            """
        )
    }

    private func roleRow(role: Role, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            RoleIconBadge(role: role, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(role.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                Text(detail)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}

private struct GameRuleSection: View {
    let title: String
    let icon: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GameRuleSectionHeader(title: title, icon: icon)

            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GameRuleSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(AppTypography.headline)
            .foregroundStyle(AppColor.label)
    }
}

#Preview {
    GameRulesSheet()
}
