import SwiftUI

struct ProfileDetailView: View {
    @Bindable var viewModel: ProfileDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    if let profile = viewModel.profile {
                        VStack(spacing: 12) {
                            AvatarView(name: profile.name, color: profile.avatarColor, size: 72)
                            Text(profile.name)
                                .font(AppTypography.title)
                                .foregroundStyle(AppColor.label)
                        }

                        statsCard(profile.stats)

                        SettingsCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Edit profile")
                                    .font(AppTypography.headline)
                                    .foregroundStyle(AppColor.label)

                                TextField("Name", text: $viewModel.draftName)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppColor.backgroundElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .foregroundStyle(AppColor.label)

                                AvatarColorPicker(selection: $viewModel.draftColor)

                                PrimaryButton(title: "Save Changes") {
                                    viewModel.saveChanges()
                                }
                            }
                            .padding(16)
                        }

                        Button(role: .destructive) {
                            viewModel.deleteProfile()
                            dismiss()
                        } label: {
                            Text("Delete Profile")
                                .font(AppTypography.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.secondaryLabel)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
    }

    private func statsCard(_ stats: PlayerProfileStats) -> some View {
        SettingsCard {
            VStack(spacing: 0) {
                statRow(title: "Total points", value: "\(stats.totalPoints)")
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Games played", value: "\(stats.gamesPlayed)")
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Win rate", value: stats.winRateLabel)
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Insider wins", value: "\(stats.winsAsInsider)")
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Mismatch wins", value: "\(stats.winsAsMismatch)")
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Ghost wins", value: "\(stats.winsAsGhost)")
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Current streak", value: "\(stats.currentStreak)")
                Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                statRow(title: "Best streak", value: "\(stats.bestStreak)")
            }
            .padding(.vertical, 8)
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.secondaryLabel)
            Spacer()
            Text(value)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct AvatarColorPicker: View {
    @Binding var selection: AvatarColor

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
            ForEach(AvatarColor.allCases, id: \.self) { color in
                Button {
                    selection = color
                } label: {
                    Circle()
                        .fill(AppColor.avatar(color))
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selection == color {
                                Circle().strokeBorder(Color.white, lineWidth: 2.5)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(color.rawValue) color")
            }
        }
    }
}
