import SwiftUI

struct LobbyQuickActionButton: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.accent)
                    Text(title)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.label)
                        .lineLimit(1)
                }

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.card.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColor.cardBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle ?? "")
    }
}

#Preview {
    HStack(spacing: 12) {
        LobbyQuickActionButton(
            title: "Word Packs",
            subtitle: "General + Pop Culture",
            systemImage: "books.vertical.fill",
            action: {}
        )
        LobbyQuickActionButton(
            title: "Rules",
            systemImage: "slider.horizontal.3",
            action: {}
        )
    }
    .padding(24)
    .background(AppColor.background)
}
