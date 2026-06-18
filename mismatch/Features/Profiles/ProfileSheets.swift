import SwiftUI

struct CreateProfileSheet: View {
    @Bindable var viewModel: ProfilesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    TextField("Player name", text: $viewModel.newProfileName)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(AppColor.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(AppColor.label)

                    AvatarColorPicker(selection: $viewModel.newProfileColor)

                    PrimaryButton(
                        title: "Create Profile",
                        isEnabled: !viewModel.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        viewModel.createProfile()
                        dismiss()
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("New Profile")
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
}

struct ProfilePickerSheet: View {
    let dependencies: AppDependencies
    let linkedProfileId: UUID?
    let onSelect: (PlayerProfile?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var profiles: [PlayerProfile] = []

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        if profiles.isEmpty {
                            Text("Create profiles from the home screen first.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColor.secondaryLabel)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(profiles) { profile in
                                Button {
                                    onSelect(profile)
                                    dismiss()
                                } label: {
                                    pickerRow(profile, isSelected: profile.id == linkedProfileId)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if linkedProfileId != nil {
                            SecondaryButton(title: "Unlink Profile") {
                                onSelect(nil)
                                dismiss()
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Link Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColor.accent)
                }
            }
            .task {
                profiles = (try? dependencies.profileRepository.fetchAll()) ?? []
            }
        }
        .preferredColorScheme(.dark)
    }

    private func pickerRow(_ profile: PlayerProfile, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            AvatarView(name: profile.name, color: profile.avatarColor, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.label)
                Text("\(profile.stats.totalPoints) pts")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.secondaryLabel)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColor.accent)
            }
        }
        .padding(12)
        .background(isSelected ? AppColor.cardSelected : AppColor.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? AppColor.accent.opacity(0.6) : AppColor.cardBorder, lineWidth: 1)
        }
    }
}
