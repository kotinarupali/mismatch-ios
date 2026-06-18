import SwiftUI

struct LobbyView: View {
    @Bindable var viewModel: LobbyViewModel
    @State private var rulesExpanded = false

    var body: some View {
        PlaceholderScreenLayout(
            title: "Lobby",
            subtitle: viewModel.statusMessage,
            icon: "person.3.fill",
            roomStyle: .lobby
        ) {
            VStack(spacing: 20) {
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

                if let shortfallMessage = viewModel.playersShortfallMessage {
                    Text(shortfallMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !viewModel.seatedPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seating order")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.label)
                            Text("Arrange players as they sit in the circle.")
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
                                    onMoveDown: { viewModel.moveSeatedPlayerDown(at: index) }
                                )
                            }
                        }
                    }
                }

                if viewModel.showsProjectedRoleCounts {
                    OutsiderCountsBanner(
                        mismatchCount: viewModel.projectedMismatchCount,
                        ghostCount: viewModel.projectedGhostCount,
                        countSuffix: "in game"
                    )
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
                    Divider().overlay(AppColor.cardBorder).padding(.horizontal, 16)
                    SettingsPickerRow(icon: "qrcode", title: "Distribution", selection: distributionModeBinding) {
                        ForEach(DistributionMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
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

    private var distributionModeBinding: Binding<DistributionMode> {
        Binding(
            get: { viewModel.distributionMode },
            set: {
                viewModel.distributionMode = $0
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
        LobbyView(viewModel: LobbyViewModel(dependencies: AppDependencies()))
    }
}
