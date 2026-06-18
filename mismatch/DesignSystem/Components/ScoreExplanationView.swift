import SwiftUI

struct ScoreExplanationView: View {
    enum Style {
        case compact
        case full
    }

    var style: Style = .full
    var onLearnMore: (() -> Void)?

    var body: some View {
        switch style {
        case .compact:
            compactBody
        case .full:
            fullBody
        }
    }

    private var compactBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("How scoring works")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                Spacer()
                if let onLearnMore {
                    Button("See all", action: onLearnMore)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)
                }
            }

            Text("Survived +1 · Win bonus +3 · Ghost guess +6")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fullBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Points add up across the whole game. Highest total wins the night — even if your team lost.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ruleRow(
                    points: ScoreReason.survived.points,
                    title: "Survived the round",
                    detail: "Everyone still in the game after each vote gets +1."
                )
                ruleRow(
                    points: ScoreReason.insiderWinBonus.points,
                    title: "Insider win bonus",
                    detail: "Surviving Insiders get +3 when the Insider side wins the game."
                )
                ruleRow(
                    points: ScoreReason.mismatchWinBonus.points,
                    title: "Mismatch win bonus",
                    detail: "Surviving Mismatch players get +3 when the Mismatch side wins."
                )
                ruleRow(
                    points: ScoreReason.ghostWinBonus.points,
                    title: "Ghost win bonus",
                    detail: "Surviving Ghosts get +3 when the Ghost side wins. With alliance on, surviving outsiders on the winning team each get +3."
                )
                ruleRow(
                    points: ScoreReason.ghostCorrectGuess.points,
                    title: "Correct ghost guess",
                    detail: "An eliminated Ghost who guesses the insider word gets +6 — even from the grave."
                )
            }

            Text("Example: survive 3 rounds (+3) and win as an Insider (+3) = 6 points.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ruleRow(points: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("+\(points)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.success)
                .frame(width: 36, alignment: .center)
                .padding(.vertical, 6)
                .background(AppColor.success.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.backgroundElevated.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ScoreExplanationSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ScoreExplanationView(style: .full)
                    .padding(20)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Scoring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColor.label)
                }
            }
        }
    }
}

#Preview("Full") {
    ScrollView {
        ScoreExplanationView(style: .full)
            .padding()
    }
    .background(AppColor.background)
}

#Preview("Compact") {
    ScoreExplanationView(style: .compact, onLearnMore: {})
        .padding()
        .background(AppColor.card)
}
