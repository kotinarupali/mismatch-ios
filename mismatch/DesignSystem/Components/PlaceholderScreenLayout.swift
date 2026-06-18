import SwiftUI

struct PlaceholderScreenLayout<Content: View>: View {
    let title: String
    let subtitle: String
    var icon: String? = nil
    var showsBrandLogo: Bool = false
    var usesHeroTitle: Bool = false
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
            if showsBrandLogo {
                MismatchLogoView(size: 56, style: .mini, showsShadow: false)
            } else if let icon {
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
                .font(usesHeroTitle ? AppTypography.display : AppTypography.largeTitle)
                .foregroundStyle(AppColor.label)
                .minimumScaleFactor(usesHeroTitle ? 0.5 : 1)
                .lineLimit(usesHeroTitle ? 1 : 2)

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
    let onEdit: (String) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var draftName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(name: isEditing ? draftName : name, color: color, size: 36)

            if isEditing {
                TextField("Player name", text: $draftName)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.label)
                    .focused($isNameFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: isNameFocused) { _, isFocused in
                        if !isFocused, isEditing {
                            commitEdit()
                        }
                    }
            } else {
                Text(name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture { beginEditing() }
            }

            if isEditing {
                Button(action: commitEdit) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColor.accent)
                }
                .buttonStyle(.plain)
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    isEditing = false
                    draftName = name
                    isNameFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: beginEditing) {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(AppColor.accentSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColor.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onChange(of: name) { _, updated in
            if !isEditing {
                draftName = updated
            }
        }
        .onAppear {
            draftName = name
        }
    }

    private func beginEditing() {
        draftName = name
        isEditing = true
        isNameFocused = true
    }

    private func commitEdit() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onEdit(trimmed)
        isEditing = false
        isNameFocused = false
    }
}

struct SeatingPlayerRow: View {
    let player: LobbySeatedPlayer
    let seatNumber: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onEdit: (String) -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onChangePlayer: () -> Void

    @State private var isEditing = false
    @State private var draftName = ""
    @FocusState private var isNameFocused: Bool

    private var displayName: String {
        player.displayName
    }

    var body: some View {
        HStack(spacing: 10) {
            Text("\(seatNumber)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
                .frame(width: 18)

            AvatarView(name: displayName, color: player.avatarColor, size: 36)

            if isEditing {
                TextField("Player name", text: $draftName)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.label)
                    .focused($isNameFocused)
                    .onSubmit { commitEdit() }
                    .onChange(of: isNameFocused) { _, isFocused in
                        if !isFocused, isEditing {
                            commitEdit()
                        }
                    }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.label)
                    if player.isHost {
                        Text("Host")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.warning)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !player.isHost else { return }
                    beginEditing()
                }
            }

            if isEditing {
                Button(action: commitEdit) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColor.accent)
                }
                .buttonStyle(.plain)
                .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    isEditing = false
                    draftName = player.displayName
                    isNameFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onChangePlayer) {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(AppColor.secondaryLabel)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change player")

                VStack(spacing: 2) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up.circle.fill")
                            .foregroundStyle(canMoveUp ? AppColor.secondaryLabel : AppColor.secondaryLabel.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)

                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down.circle.fill")
                            .foregroundStyle(canMoveDown ? AppColor.secondaryLabel : AppColor.secondaryLabel.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)
                }

                if player.isHost {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(AppColor.warning)
                } else {
                    Button(action: beginEditing) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(AppColor.accentSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(player.isHost ? AppColor.backgroundElevated.opacity(0.9) : AppColor.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            if player.isHost {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColor.warning.opacity(0.35), lineWidth: 1)
            }
        }
        .onAppear {
            draftName = player.displayName
        }
        .onChange(of: player.displayName) { _, updated in
            if !isEditing {
                draftName = updated
            }
        }
    }

    private func beginEditing() {
        draftName = player.displayName
        isEditing = true
        isNameFocused = true
    }

    private func commitEdit() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onEdit(trimmed)
        isEditing = false
        isNameFocused = false
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
