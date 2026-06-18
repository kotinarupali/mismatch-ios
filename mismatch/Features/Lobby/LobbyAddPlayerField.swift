import SwiftUI

struct LobbyAddPlayerField: View {
    @Bindable var viewModel: LobbyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("Player name", text: $viewModel.newPlayerName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(AppColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(AppColor.cardBorder, lineWidth: 1)
                    }
                    .foregroundStyle(AppColor.label)
                    .onSubmit { viewModel.addPlayer() }

                Button {
                    viewModel.addPlayer()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColor.heroGradient)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canAddPlayer)
            }

            if viewModel.showsProfileSuggestions {
                suggestionsDropdown
            }
        }
    }

    @ViewBuilder
    private var suggestionsDropdown: some View {
        if viewModel.profileSuggestions.isEmpty {
            Text("Press + to add \"\(viewModel.newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines))\" as a new player.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.secondaryLabel)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        } else {
            VStack(spacing: 0) {
                ForEach(viewModel.profileSuggestions) { profile in
                    Button {
                        viewModel.selectSuggestedProfile(profile)
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: profile.name, color: profile.avatarColor, size: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.label)
                                Text("\(profile.stats.totalPoints) pts · \(profile.stats.gamesPlayed) games")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.secondaryLabel)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "arrow.turn.down.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColor.accent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)

                    if profile.id != viewModel.profileSuggestions.last?.id {
                        Divider().overlay(AppColor.cardBorder).padding(.leading, 56)
                    }
                }
            }
            .background(AppColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppColor.cardBorder, lineWidth: 1)
            }
        }
    }
}

#Preview {
    ZStack {
        AppColor.background.ignoresSafeArea()
        LobbyAddPlayerField(viewModel: LobbyViewModel(dependencies: AppDependencies()))
            .padding(24)
    }
}
