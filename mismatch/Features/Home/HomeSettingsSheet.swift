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
}
