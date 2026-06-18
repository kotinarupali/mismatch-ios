import SwiftUI

struct RoundProgressBanner: View {
    let gamesPlayedCount: Int
    let eliminationRoundsInCurrentGame: Int
    let leaderName: String?
    var style: Style = .standard

    enum Style {
        case standard
        case compact
    }

    private var progressLabel: String {
        GameProgressCopy.scoreBannerTitle(
            gamesPlayed: gamesPlayedCount,
            eliminationsInCurrentGame: eliminationRoundsInCurrentGame
        )
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.system(size: style == .compact ? 16 : 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: style == .compact ? 36 : 40, height: style == .compact ? 36 : 40)
                .background(AppColor.accent.opacity(0.85))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(progressLabel)
                    .font(style == .compact ? AppTypography.headline : AppTypography.title)
                    .foregroundStyle(AppColor.label)

                if let leaderName {
                    Text("\(leaderName) leads the scores")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                } else if gamesPlayedCount == 0, eliminationRoundsInCurrentGame == 0 {
                    Text("Scores start after the first elimination")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                } else if gamesPlayedCount > 0, eliminationRoundsInCurrentGame == 0 {
                    Text("Ready for game \(gamesPlayedCount + 1)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, style == .compact ? 10 : 12)
        .padding(.horizontal, 12)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}

struct ScoresDashboardSheet: View {
    @Bindable var store: GameSessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showScoreExplanation = false

    private var scoreboard: [SessionScoreRow] {
        store.sessionScoreboard()
    }

    private var leaderName: String? {
        guard scoreboard.contains(where: { $0.sessionScore > 0 }) else { return nil }
        return scoreboard.first?.displayName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    RoundProgressBanner(
                        gamesPlayedCount: store.gamesPlayedCount,
                        eliminationRoundsInCurrentGame: store.eliminationRoundsInCurrentGame,
                        leaderName: leaderName
                    )

                    SessionScoreboardView(
                        title: "Leaderboard",
                        rows: scoreboard,
                        showsRoundPoints: false,
                        highlightTopRank: store.eliminationRoundsInCurrentGame > 0 && leaderName != nil
                    )

                    ScoreExplanationView(style: .compact) {
                        showScoreExplanation = true
                    }
                    .padding(14)
                    .background(AppColor.card.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(20)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showScoreExplanation = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(AppColor.label)
                    }
                    .accessibilityLabel("How scoring works")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColor.label)
                }
            }
            .sheet(isPresented: $showScoreExplanation) {
                ScoreExplanationSheet()
            }
        }
    }
}

#Preview {
    ScoresDashboardSheet(store: GameSessionStore())
}
