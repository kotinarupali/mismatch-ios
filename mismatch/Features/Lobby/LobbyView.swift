import SwiftUI

struct LobbyView: View {
    @Bindable var viewModel: LobbyViewModel
    let dependencies: AppDependencies
    @State private var rulesExpanded = false

    var body: some View {
        PlaceholderScreenLayout(
            title: "Lobby",
            subtitle: viewModel.statusMessage,
            icon: "person.3.fill",
            roomStyle: .lobby
        ) {
            VStack(spacing: 20) {
                SecondaryButton(title: "Add Player") {
                    viewModel.openAddPlayerPicker()
                }

                if let shortfallMessage = viewModel.playersShortfallMessage {
                    Text(shortfallMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if viewModel.showsProjectedRoleCounts {
                    OutsiderCountsBanner(
                        mismatchCount: viewModel.projectedMismatchCount,
                        ghostCount: viewModel.projectedGhostCount,
                        countSuffix: "in game",
                        style: .lobby
                    )
                }

                if !viewModel.seatedPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seating order")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.label)
                            Text("Arrange players as they sit in the circle. Tap a seat to swap players.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.seatedPlayers.enumerated()), id: \.element.id) { index, player in
                                SeatingPlayerRow(
                                    player: player,
                                    seatNumber: index + 1,
                                    canMoveUp: index > 0,
                                    canMoveDown: index < viewModel.seatedPlayers.count - 1,
                                    onEdit: { viewModel.updatePlayer(id: player.id, name: $0) },
                                    onDelete: { viewModel.removePlayer(id: player.id) },
                                    onMoveUp: { viewModel.moveSeatedPlayerUp(at: index) },
                                    onMoveDown: { viewModel.moveSeatedPlayerDown(at: index) },
                                    onChangePlayer: { viewModel.openChangePlayerPicker(for: player.id) }
                                )
                            }
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

                rulesSection
            }
        }
        .navigationTitle("Lobby")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.background.opacity(0.9), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $viewModel.showPlayerPicker) {
            LobbyPlayerPickerSheet(
                profiles: viewModel.availableProfilesForPicker(),
                excludedProfileIds: viewModel.excludedProfileIdsForPicker,
                allowsHostSelection: viewModel.playerPickerAllowsHostSelection,
                onSelectProfile: { viewModel.addPlayer(from: $0) },
                onAddNewPlayer: { viewModel.addNewPlayer(named: $0) }
            )
        }
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    rulesExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rules")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.label)
                        if !rulesExpanded {
                            Text(viewModel.rulesSummary)
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.secondaryLabel)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColor.secondaryLabel)
                        .rotationEffect(.degrees(rulesExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if rulesExpanded {
                SettingsCard {
                    SettingsToggleRow(
                        icon: "person.crop.circle.badge.checkmark",
                        title: "I'm playing",
                        isOn: hostIsPlayingBinding
                    )
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(
                        icon: "eye.slash.fill",
                        title: "Show role on card",
                        isOn: showRoleOnCardBinding
                    )
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(
                        icon: "figure.wave",
                        title: "Ghost",
                        isOn: ghostEnabledBinding
                    )
                    .disabled(!viewModel.canToggleGhost)
                    .opacity(viewModel.canToggleGhost ? 1 : 0.45)
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(
                        icon: "person.2.fill",
                        title: "Mismatch & Ghost alliance",
                        isOn: mismatchGhostAllianceBinding
                    )
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsToggleRow(
                        icon: "timer",
                        title: "Discussion timer",
                        isOn: discussionTimerEnabledBinding
                    )

                    if viewModel.discussionTimerEnabled {
                        Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                        SettingsPickerRow(
                            icon: "clock.fill",
                            title: "Duration",
                            selection: timerMinutesBinding
                        ) {
                            ForEach(HostPreferences.allowedTimerMinutes, id: \.self) { minutes in
                                Text(minutes == 1 ? "1 minute" : "\(minutes) minutes").tag(minutes)
                            }
                        }
                    }

                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsPickerRow(icon: "qrcode", title: "Distribution", selection: distributionModeBinding) {
                        ForEach(DistributionMode.lobbyOptions, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }

                    Text(viewModel.distributionMode.detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, viewModel.showsCloudGuestVotingToggle ? 0 : 12)

                    if viewModel.showsCloudGuestVotingToggle {
                        Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                        SettingsToggleRow(
                            icon: "hand.raised.fill",
                            title: "Guest voting on phones",
                            isOn: cloudGuestVotingBinding
                        )
                        Text("Guests cast votes in their browser during discussion. You still confirm the elimination.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.secondaryLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    private var hostIsPlayingBinding: Binding<Bool> {
        Binding(
            get: { viewModel.hostIsPlaying },
            set: {
                viewModel.hostIsPlaying = $0
                viewModel.refreshSession()
            }
        )
    }

    private var showRoleOnCardBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showRoleOnCard },
            set: {
                viewModel.showRoleOnCard = $0
                viewModel.refreshSession()
            }
        )
    }

    private var mismatchGhostAllianceBinding: Binding<Bool> {
        Binding(
            get: { viewModel.mismatchGhostAlliance },
            set: {
                viewModel.mismatchGhostAlliance = $0
                viewModel.refreshSession()
            }
        )
    }

    private var discussionTimerEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.discussionTimerEnabled },
            set: {
                viewModel.discussionTimerEnabled = $0
                viewModel.refreshSession()
            }
        )
    }

    private var timerMinutesBinding: Binding<Int> {
        Binding(
            get: { viewModel.timerMinutes },
            set: {
                viewModel.timerMinutes = $0
                viewModel.refreshSession()
            }
        )
    }

    private var distributionModeBinding: Binding<DistributionMode> {
        Binding(
            get: { viewModel.distributionMode },
            set: {
                viewModel.distributionMode = $0
                viewModel.refreshSession()
            }
        )
    }

    private var cloudGuestVotingBinding: Binding<Bool> {
        Binding(
            get: { viewModel.cloudGuestVotingEnabled },
            set: {
                viewModel.cloudGuestVotingEnabled = $0
                viewModel.refreshSession()
            }
        )
    }

    private var ghostEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.ghostEnabled },
            set: { viewModel.setGhostEnabled($0) }
        )
    }
}

#Preview {
    NavigationStack {
        LobbyView(
            viewModel: LobbyViewModel(dependencies: AppDependencies()),
            dependencies: AppDependencies()
        )
    }
}
