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
}

struct FinalScoreboardView: View {
    let rows: [FinalScoreboardRow]

    private let avatarSize: CGFloat = 44
    private let crownSlotHeight: CGFloat = 18
    private let columnWidth: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Final scores")
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

    private func scoreRow(_ row: FinalScoreboardRow) -> some View {
        HStack(alignment: .center, spacing: 12) {
            playerColumn(row)

            Text(row.displayName)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
                .lineLimit(1)

            Spacer(minLength: 8)

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
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(row.isWinner ? AppColor.warning.opacity(0.12) : AppColor.backgroundElevated.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            if row.isWinner {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(AppColor.warning.opacity(0.45), lineWidth: 1.5)
            }
        }
        .accessibilityLabel(accessibilityLabel(for: row))
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

            ZStack(alignment: .bottomTrailing) {
                AvatarView(name: row.displayName, color: row.avatarColor, size: avatarSize)

                RoleOverlayMark(role: row.role, size: 14)
                    .padding(2)
            }
            .frame(width: avatarSize, height: avatarSize)
        }
        .frame(width: columnWidth, alignment: .center)
    }

    private func accessibilityLabel(for row: FinalScoreboardRow) -> String {
        var label = "\(row.displayName), \(row.role.displayName), \(row.sessionScore) points"
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
                displayName: "A",
                avatarColor: .green,
                role: .insider,
                sessionScore: 5,
                pointsGained: 4,
                rank: 1,
                isWinner: true
            ),
            FinalScoreboardRow(
                id: UUID(),
                displayName: "B",
                avatarColor: .yellow,
                role: .insider,
                sessionScore: 5,
                pointsGained: 4,
                rank: 2,
                isWinner: true
            ),
            FinalScoreboardRow(
                id: UUID(),
                displayName: "C",
                avatarColor: .teal,
                role: .ghost,
                sessionScore: 1,
                pointsGained: 0,
                rank: 3,
                isWinner: false
            ),
            FinalScoreboardRow(
                id: UUID(),
                displayName: "You",
                avatarColor: .blue,
                role: .mismatch,
                sessionScore: 0,
                pointsGained: 0,
                rank: 4,
                isWinner: false
            )
        ]
    )
    .padding()
    .background(AppColor.background)
}
