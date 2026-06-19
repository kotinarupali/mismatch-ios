import SwiftUI

struct HomeSettingsSheet: View {
    @Bindable var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Defaults for your next game night. You can still tweak rules in the lobby.")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)

                        SettingsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Your name", systemImage: "person.fill")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.label)

                                TextField("Name shown in the game", text: hostDisplayNameBinding)
                                    .textFieldStyle(.plain)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.label)
                                    .textInputAutocapitalization(.words)
                                    .autocorrectionDisabled()
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(AppColor.backgroundElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Text("Used on your player card and scoreboards instead of \"You\".")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.secondaryLabel)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }

                        SettingsCard {
                            SettingsToggleRow(
                                icon: "timer",
                                title: "Discussion timer",
                                isOn: discussionTimerBinding
                            )

                            if viewModel.preferences.discussionTimerEnabled {
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
                                .padding(.bottom, 8)
                            } else {
                                Text("Turn on to limit discussion time each round.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.secondaryLabel)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                            }
                        }

                        SettingsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Data", systemImage: "externaldrive.fill")
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColor.label)

                                Text("Removes all player profiles and resets word-pack usage so every pair can appear again. Your name and timer defaults are kept.")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.secondaryLabel)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    viewModel.showClearDataConfirmation = true
                                } label: {
                                    Text("Clear Data & Reset Words")
                                        .font(AppTypography.body)
                                        .foregroundStyle(AppColor.accentSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.background.opacity(0.95), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColor.accent)
                }
            }
            .confirmDialog(
                isPresented: $viewModel.showClearDataConfirmation,
                title: "Clear data and reset words?",
                message: "All player profiles and their stats will be deleted. Every word pair will be marked unused again. This cannot be undone.",
                confirmTitle: "Clear & Reset"
            ) {
                viewModel.clearDataAndResetWords()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var discussionTimerBinding: Binding<Bool> {
        Binding(
            get: { viewModel.preferences.discussionTimerEnabled },
            set: { viewModel.setDiscussionTimerEnabled($0) }
        )
    }

    private var timerMinutesBinding: Binding<Int> {
        Binding(
            get: { viewModel.preferences.timerMinutes },
            set: { viewModel.setTimerMinutes($0) }
        )
    }

    private var hostDisplayNameBinding: Binding<String> {
        Binding(
            get: { viewModel.preferences.hostDisplayName },
            set: { viewModel.setHostDisplayName($0) }
        )
    }
}
