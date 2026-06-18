import SwiftUI

struct OutsiderCountsBanner: View {
    enum Style {
        case full
        case compact
        case lobby
    }

    let mismatchCount: Int
    let ghostCount: Int
    var countSuffix: String
    var style: Style = .full
    var showsGhostCount: Bool = true

    var body: some View {
        switch style {
        case .full:
            fullBanner
        case .compact:
            compactTray
        case .lobby:
            lobbyBanner
        }
    }

    private var fullBanner: some View {
        HStack(spacing: 12) {
            fullCountChip(role: .mismatch, count: mismatchCount)
            if showsGhostCount {
                fullCountChip(role: .ghost, count: ghostCount)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var compactTray: some View {
        HStack(spacing: 8) {
            compactCountChip(role: .mismatch, count: mismatchCount)
            if showsGhostCount {
                compactCountChip(role: .ghost, count: ghostCount)
            }
        }
    }

    private var lobbyBanner: some View {
        HStack(spacing: 8) {
            lobbyCountChip(role: .mismatch, count: mismatchCount)
            if showsGhostCount {
                lobbyCountChip(role: .ghost, count: ghostCount)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func lobbyCountChip(role: Role, count: Int) -> some View {
        HStack(spacing: 10) {
            RoleIconBadge(role: role, size: .small)

            VStack(alignment: .leading, spacing: 1) {
                Text(role.displayName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                Text("\(count) \(countSuffix)")
                    .font(AppTypography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColor.label)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColor.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel("\(role.displayName), \(count) \(countSuffix)")
    }

    private func fullCountChip(role: Role, count: Int) -> some View {
        HStack(spacing: 10) {
            RoleIconBadge(role: role, size: .extraLarge)
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

    private func compactCountChip(role: Role, count: Int) -> some View {
        HStack(spacing: 6) {
            RoleIconBadge(role: role, size: .small)
            Text("\(count)")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(AppColor.card.opacity(0.9))
        .clipShape(Capsule())
        .overlay {
            Capsule().strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
        .accessibilityLabel("\(role.displayName), \(count) \(countSuffix)")
    }
}
