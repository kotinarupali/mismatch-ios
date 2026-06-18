import SwiftUI

struct SessionScoreboardView: View {
    let title: String
    let rows: [SessionScoreRow]
    var showsRoundPoints: Bool = true
    var showsRoundPointsBubble: Bool = false
    var highlightTopRank: Bool = false

    private let avatarSize: CGFloat = 40
    private let crownSlotHeight: CGFloat = 18
    private let columnWidth: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                ForEach(rows) { row in
                    scoreRow(row)
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

    private func scoreRow(_ row: SessionScoreRow) -> some View {
        let isLeader = highlightTopRank && row.rank == 1

        return HStack(spacing: 12) {
            Text("\(row.rank)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(isLeader ? AppColor.warning : AppColor.secondaryLabel)
                .frame(width: 24, alignment: .center)
                .accessibilityHidden(true)

            playerColumn(row, isLeader: isLeader)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                    .lineLimit(1)

                if showsRoundPoints, !showsRoundPointsBubble, row.roundPoints > 0 {
                    Text("+\(row.roundPoints) this round")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.success)
                } else if showsRoundPoints, !showsRoundPointsBubble, row.roundPoints == 0, !highlightTopRank {
                    Text("No points this round")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                }
            }

            Spacer(minLength: 8)

            scoreColumn(row, isLeader: isLeader)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(isLeader ? AppColor.warning.opacity(0.12) : AppColor.backgroundElevated.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel(scoreRowAccessibilityLabel(for: row, isLeader: isLeader))
    }

    private func playerColumn(_ row: SessionScoreRow, isLeader: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if isLeader {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.warning)
                        .shadow(color: AppColor.warning.opacity(0.5), radius: 5, y: 2)
                }
            }
            .frame(width: columnWidth, height: crownSlotHeight)

            AvatarView(name: row.displayName, color: row.avatarColor, size: avatarSize)
        }
        .frame(width: columnWidth, alignment: .center)
    }

    private func scoreColumn(_ row: SessionScoreRow, isLeader: Bool) -> some View {
        HStack(spacing: 8) {
            if showsRoundPointsBubble, row.roundPoints > 0 {
                Text("+\(row.roundPoints)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.success.opacity(0.14))
                    .clipShape(Capsule())
            }

            Text("\(row.sessionScore)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(isLeader ? AppColor.warning : AppColor.label)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(scoreColumnAccessibilityLabel(for: row))
    }

    private func scoreColumnAccessibilityLabel(for row: SessionScoreRow) -> String {
        if showsRoundPointsBubble, row.roundPoints > 0 {
            return "\(row.sessionScore) total points, plus \(row.roundPoints) this game"
        }
        return "\(row.sessionScore) total points"
    }

    private func scoreRowAccessibilityLabel(for row: SessionScoreRow, isLeader: Bool) -> String {
        var label = "Rank \(row.rank), \(row.displayName), \(row.sessionScore) total points"
        if isLeader {
            label += ", leading"
        }
        if showsRoundPoints, !showsRoundPointsBubble, row.roundPoints > 0 {
            label += ", plus \(row.roundPoints) this round"
        }
        return label
    }
}

struct RoundScoreBreakdownView: View {
    var title: String = "Points this round"
    let events: [ScoreEvent]
    let players: [PlayerSlot]
    var showsLegend: Bool = true
    var onShowScoreExplanation: (() -> Void)? = nil

    private var groupedRows: [(player: PlayerSlot, events: [ScoreEvent], total: Int)] {
        let lookup = Dictionary(uniqueKeysWithValues: players.map { ($0.id, $0) })
        let grouped = Dictionary(grouping: events, by: \.playerId)
        return grouped.compactMap { playerId, playerEvents -> (PlayerSlot, [ScoreEvent], Int)? in
            guard let player = lookup[playerId] else { return nil }
            let total = ScoringEngine.totalPoints(for: playerEvents)
            guard total > 0 else { return nil }
            return (player, playerEvents.sorted { $0.reason.points > $1.reason.points }, total)
        }
        .sorted { $0.total > $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
                .frame(maxWidth: .infinity, alignment: .leading)

            if groupedRows.isEmpty {
                Text("No one earned points this round.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            } else {
                VStack(spacing: 8) {
                    ForEach(groupedRows, id: \.player.id) { row in
                        breakdownRow(player: row.player, events: row.events, total: row.total)
                    }
                }
            }

            if showsLegend {
                ScoreExplanationView(style: .compact, onLearnMore: onShowScoreExplanation)
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

    private func breakdownRow(player: PlayerSlot, events: [ScoreEvent], total: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(
                name: player.displayName,
                color: player.avatarColor,
                size: 36
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)

                Text(events.map(\.reason.label).joined(separator: " · "))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text("+\(total)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColor.success)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppColor.backgroundElevated.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview("Session leaderboard") {
    SessionScoreboardView(
        title: "Tonight's scores",
        rows: ScoringEngine.sampleScoreboard(),
        showsRoundPoints: true,
        showsRoundPointsBubble: true,
        highlightTopRank: true
    )
    .padding()
    .background(AppColor.background)
}

#Preview("Round breakdown") {
    RoundScoreBreakdownView(
        events: ScoringEngine.sampleRoundEvents(),
        players: [
            PlayerSlot(displayName: "Alex", avatarColor: .green, assignment: RoleAssignment(role: .mismatch, word: "B")),
            PlayerSlot(displayName: "Jordan", avatarColor: .orange, assignment: RoleAssignment(role: .ghost, word: nil)),
            PlayerSlot(displayName: "You", avatarColor: .blue, isHost: true, assignment: RoleAssignment(role: .insider, word: "A"))
        ]
    )
    .padding()
    .background(AppColor.background)
}
