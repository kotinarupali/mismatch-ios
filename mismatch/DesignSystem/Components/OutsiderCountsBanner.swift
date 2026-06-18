import SwiftUI

struct OutsiderCountsBanner: View {
    let mismatchCount: Int
    let ghostCount: Int
    var countSuffix: String

    var body: some View {
        HStack(spacing: 12) {
            countChip(role: .mismatch, count: mismatchCount)
            countChip(role: .ghost, count: ghostCount)
        }
        .frame(maxWidth: .infinity)
    }

    private func countChip(role: Role, count: Int) -> some View {
        HStack(spacing: 10) {
            RoleIconBadge(role: role, size: .large)
            VStack(alignment: .leading, spacing: 2) {
                Text(role.displayName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                Text("\(count) \(countSuffix)")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
        .accessibilityLabel("\(role.displayName), \(count) \(countSuffix)")
    }
}
