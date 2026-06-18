import SwiftUI

struct LobbyView: View {
    @Bindable var viewModel: LobbyViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Lobby",
            subtitle: viewModel.statusMessage,
            icon: "person.3.fill",
            roomStyle: .lobby
        ) {
            VStack(spacing: 20) {
                SettingsCard {
                    SettingsToggleRow(icon: "person.crop.circle.badge.checkmark", title: "I'm playing", isOn: $viewModel.hostIsPlaying)
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(icon: "eye.slash.fill", title: "Show role on card", isOn: $viewModel.showRoleOnCard)
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(
                        icon: "person.2.fill",
                        title: "Mismatch & Ghost alliance",
                        isOn: $viewModel.mismatchGhostAlliance
                    )
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(icon: "timer", title: "Discussion timer", isOn: $viewModel.discussionTimerEnabled)
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsPickerRow(icon: "qrcode", title: "Distribution", selection: $viewModel.distributionMode) {
                        ForEach(DistributionMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }
                .onChange(of: viewModel.hostIsPlaying) { viewModel.refreshSession() }
                .onChange(of: viewModel.mismatchGhostAlliance) { viewModel.refreshSession() }
                .onChange(of: viewModel.discussionTimerEnabled) { viewModel.refreshSession() }
                .onChange(of: viewModel.showRoleOnCard) { viewModel.refreshSession() }
                .onChange(of: viewModel.distributionMode) { viewModel.refreshSession() }

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
                    .disabled(!viewModel.canAddPlayer)
                }

                if viewModel.hostIsPlaying {
                    HostPlayerChip()
                }

                if let shortfallMessage = viewModel.playersShortfallMessage {
                    Text(shortfallMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !viewModel.playerNames.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.playerNames.enumerated()), id: \.offset) { index, name in
                            PlayerChip(
                                name: name,
                                color: viewModel.playerColors[index],
                                onEdit: { viewModel.updatePlayer(at: index, name: $0) },
                                onDelete: { viewModel.removePlayer(at: index) }
                            )
                        }
                    }
                }

                PrimaryButton(
                    title: viewModel.isDistributing ? "Dealing roles…" : "Distribute Roles",
                    isEnabled: viewModel.canContinue
                ) {
                    viewModel.distributeRolesTapped()
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accentSecondary)
                }
            }
        }
        .navigationTitle("Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        LobbyView(viewModel: LobbyViewModel(dependencies: AppDependencies()))
    }
}
