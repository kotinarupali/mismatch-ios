import SwiftUI

struct PlaceholderScreenLayout<Content: View>: View {
    let title: String
    let subtitle: String
    var icon: String? = nil
    var roomStyle: PartyRoomStyle = .lobby
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            PartyRoomBackground(style: roomStyle)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    content
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColor.heroGradient)
                    .padding(12)
                    .background(AppColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                    }
            }

            Text(title)
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColor.label)

            Text(subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    if isEnabled {
                        AppColor.heroGradient
                    } else {
                        Color.white.opacity(0.12)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: isEnabled ? AppColor.accent.opacity(0.35) : .clear, radius: 12, y: 6)
        }
        .disabled(!isEnabled)
        .accessibilityHint(title)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColor.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                }
        }
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.vertical, 4)
        .background(AppColor.card.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: icon)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.label)
        }
        .tint(AppColor.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsPickerRow<Selection: Hashable, Content: View>: View {
    let icon: String
    let title: String
    @Binding var selection: Selection
    @ViewBuilder var content: Content

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.label)
            Spacer()
            Picker(title, selection: $selection) {
                content
            }
            .labelsHidden()
            .tint(AppColor.accentSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct PlayerChip: View {
    let name: String
    let color: AvatarColor
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(name: name, color: color, size: 36)
            Text(name)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.label)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColor.secondaryLabel)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColor.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct OutcomeCard: View {
    let title: String
    let value: String
    var icon: String = "person.fill"

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppColor.heroGradient)
                .frame(width: 44, height: 44)
                .background(AppColor.backgroundElevated)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
                Text(value)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}
