import SwiftUI

struct WordPackSelectionSection: View {
    let packs: [WordPackSummary]
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Word packs")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.label)
                Text("Pick one or more packs. Words are drawn randomly from your selection.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)

            SettingsCard {
                ForEach(Array(packs.enumerated()), id: \.element.id) { index, pack in
                    if index > 0 {
                        Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    }

                    Button {
                        onToggle(pack.id)
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: pack.isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(pack.isSelected ? AppColor.accent : AppColor.secondaryLabel.opacity(0.7))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(pack.displayName)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.label)
                                Text("\(pack.stats.used) of \(pack.stats.total) words used")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.secondaryLabel)
                            }

                            Spacer(minLength: 8)

                            Text("\(pack.stats.remaining) left")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel.opacity(0.9))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(pack.displayName), \(pack.stats.used) of \(pack.stats.total) words used")
                    .accessibilityValue(pack.isSelected ? "Selected" : "Not selected")
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        WordPackSelectionSection(
            packs: [
                WordPackSummary(id: "general", displayName: "General", stats: WordPairStats(used: 42, remaining: 958, total: 1000), isSelected: true),
                WordPackSummary(id: "pop_culture", displayName: "Pop Culture", stats: WordPairStats(used: 10, remaining: 240, total: 250), isSelected: false),
            ],
            onToggle: { _ in }
        )
        .padding()
    }
    .background(AppColor.background)
}
