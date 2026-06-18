import SwiftUI

struct LobbyPlayerPickerSheet: View {
    let profiles: [PlayerProfile]
    let excludedProfileIds: Set<UUID>
    let allowsHostSelection: Bool
    let onSelectProfile: (PlayerProfile) -> Void
    let onAddNewPlayer: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newPlayerName = ""

    private var availableProfiles: [PlayerProfile] {
        profiles.filter { !excludedProfileIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("New player")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColor.label)

                            HStack(spacing: 10) {
                                TextField("Player name", text: $newPlayerName)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(AppColor.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .foregroundStyle(AppColor.label)
                                    .onSubmit { addNewPlayer() }

                                Button(action: addNewPlayer) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(AppColor.heroGradient)
                                }
                                .buttonStyle(.plain)
                                .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }

                            Text("New names are saved automatically for next time.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Saved players")
                                .font(AppTypography.headline)
                                .foregroundStyle(AppColor.label)

                            if availableProfiles.isEmpty {
                                Text("No saved players yet — add someone above.")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.secondaryLabel)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(availableProfiles) { profile in
                                        Button {
                                            onSelectProfile(profile)
                                            dismiss()
                                        } label: {
                                            pickerRow(profile)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(allowsHostSelection ? "Choose Player" : "Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addNewPlayer() {
        let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddNewPlayer(trimmed)
        dismiss()
    }

    private func pickerRow(_ profile: PlayerProfile) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: profile.name, color: profile.avatarColor, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                Text("\(profile.stats.totalPoints) pts · \(profile.stats.gamesPlayed) games")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
            Spacer()
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(AppColor.accent)
        }
        .padding(12)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}
