import SwiftUI

struct ProfilesListView: View {
    @Bindable var viewModel: ProfilesViewModel

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Players are saved automatically when you add them in the lobby. Stats stay on this device.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.accentSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if viewModel.profiles.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 8) {
                            ForEach(viewModel.profiles) { profile in
                                NavigationLink(value: profile.id) {
                                    profileRow(profile)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Profiles")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(for: UUID.self) { profileId in
            ProfileDetailView(viewModel: viewModel.detailViewModel(for: profileId))
        }
        .onAppear { viewModel.onAppear() }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No players yet")
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.label)
            Text("Host a game and add guests in the lobby — they'll show up here automatically.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func profileRow(_ profile: PlayerProfile) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: profile.name, color: profile.avatarColor, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                Text("\(profile.stats.totalPoints) pts · \(profile.stats.gamesPlayed) games")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.secondaryLabel)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(AppColor.cardBorder, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        ProfilesListView(viewModel: ProfilesViewModel(dependencies: AppDependencies()))
    }
}
