import SwiftUI

struct FinalScoreboardRow: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let avatarColor: AvatarColor
    let role: Role
    let sessionScore: Int
    let pointsGained: Int
    let rank: Int
    let isWinner: Bool
    let isEliminated: Bool
}

struct FinalScoreboardView: View {
    let rows: [FinalScoreboardRow]

    private let avatarSize: CGFloat = 44
    private let crownSlotHeight: CGFloat = 18
    private let columnWidth: CGFloat = 44

    private var eliminatedSummary: String? {
        let names = rows.filter(\.isEliminated).map(\.displayName)
        guard !names.isEmpty else { return nil }
        if names.count == 1 {
            return "Voted out: \(names[0])"
        }
        return "Voted out: \(names.joined(separator: ", "))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Final scores")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)

                if let eliminatedSummary {
                    Text(eliminatedSummary)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accentSecondary)
                }
            }
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

    private func scoreRow(_ row: FinalScoreboardRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            playerColumn(row)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.displayName)
                    .font(AppTypography.headline)
                    .foregroundStyle(row.isEliminated ? AppColor.secondaryLabel : AppColor.label)
                    .lineLimit(1)

                playerMeta(row)
            }

            Spacer(minLength: 8)

            scoreColumn(row)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(rowBackground(for: row))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            if row.isWinner {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColor.warning.opacity(0.45), lineWidth: 1.5)
            } else if row.isEliminated {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColor.accentSecondary.opacity(0.35), lineWidth: 1)
            }
        }
        .opacity(row.isEliminated && !row.isWinner ? 0.88 : 1)
        .accessibilityLabel(accessibilityLabel(for: row))
    }

    private func playerMeta(_ row: FinalScoreboardRow) -> some View {
        HStack(spacing: 6) {
            RoleIconBadge(role: row.role, size: .tiny)

            Text(row.role.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(roleColor(for: row.role))

            if row.isWinner {
                Text("Winner")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.warning)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppColor.warning.opacity(0.18))
                    .clipShape(Capsule())
            } else if row.isEliminated {
                Text("Eliminated")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppColor.accentSecondary.opacity(0.92))
                    .clipShape(Capsule())
            } else {
                Text("In")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColor.success)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(AppColor.success.opacity(0.16))
                    .clipShape(Capsule())
            }
        }
    }

    private func scoreColumn(_ row: FinalScoreboardRow) -> some View {
        HStack(spacing: 8) {
            if row.pointsGained > 0 {
                Text("+\(row.pointsGained)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColor.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.success.opacity(0.14))
                    .clipShape(Capsule())
            }

            Text("\(row.sessionScore)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(row.isWinner ? AppColor.warning : AppColor.label)
                .accessibilityLabel("\(row.sessionScore) total points")
        }
    }

    private func playerColumn(_ row: FinalScoreboardRow) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if row.isWinner {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.warning)
                        .shadow(color: AppColor.warning.opacity(0.5), radius: 5, y: 2)
                }
            }
            .frame(width: columnWidth, height: crownSlotHeight)

            ZStack {
                AvatarView(name: row.displayName, color: row.avatarColor, size: avatarSize)
                    .opacity(row.isEliminated && !row.isWinner ? 0.42 : 1)

                if row.isEliminated && !row.isWinner {
                    Circle()
                        .strokeBorder(AppColor.accentSecondary.opacity(0.85), lineWidth: 2.5)

                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(AppColor.accentSecondary)
                        .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
                }
            }
            .frame(width: avatarSize, height: avatarSize)
        }
        .frame(width: columnWidth, alignment: .center)
    }

    private func rowBackground(for row: FinalScoreboardRow) -> Color {
        if row.isWinner {
            return AppColor.warning.opacity(0.12)
        }
        if row.isEliminated {
            return AppColor.accentSecondary.opacity(0.08)
        }
        return AppColor.backgroundElevated.opacity(0.85)
    }

    private func roleColor(for role: Role) -> Color {
        switch role {
        case .insider: BrandPalette.insiderMid
        case .mismatch: BrandPalette.mismatchMid
        case .ghost: BrandPalette.ghostMid
        }
    }

    private func accessibilityLabel(for row: FinalScoreboardRow) -> String {
        var label = "\(row.displayName), \(row.role.displayName)"
        label += row.isEliminated ? ", eliminated" : ", still in"
        label += ", \(row.sessionScore) points"
        if row.pointsGained > 0 {
            label += ", plus \(row.pointsGained)"
        }
        if row.isWinner {
            label += ", winner"
        }
        return label
    }
}

#Preview {
    FinalScoreboardView(
        rows: [
            FinalScoreboardRow(
                id: UUID(),
                displayName: "Adrian",
                avatarColor: .orange,
                role: .insider,
                sessionScore: 5,
                pointsGained: 5,
                rank: 1,
                isWinner: true,
                isEliminated: false
            ),
            FinalScoreboardRow(
                id: UUID(),
                displayName: "You",
                avatarColor: .blue,
                role: .insider,
                sessionScore: 5,
                pointsGained: 5,
                rank: 2,
                isWinner: true,
                isEliminated: false
            ),
            FinalScoreboardRow(
                id: UUID(),
                displayName: "Carol",
                avatarColor: .green,
                role: .mismatch,
                sessionScore: 1,
                pointsGained: 1,
                rank: 3,
                isWinner: false,
                isEliminated: true
            ),
            FinalScoreboardRow(
                id: UUID(),
                displayName: "Ben",
                avatarColor: .yellow,
                role: .insider,
                sessionScore: 0,
                pointsGained: 0,
                rank: 4,
                isWinner: false,
                isEliminated: true
            )
        ]
    )
    .padding()
    .background(AppColor.background)
}
