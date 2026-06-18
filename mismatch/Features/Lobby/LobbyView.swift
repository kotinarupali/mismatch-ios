import SwiftUI

struct LobbyView: View {
    @Bindable var viewModel: LobbyViewModel

    var body: some View {
        PlaceholderScreenLayout(
            title: "Lobby",
            subtitle: viewModel.statusMessage
        ) {
            VStack(spacing: 16) {
                Form {
                    Toggle("I'm playing", isOn: $viewModel.hostIsPlaying)
                    Toggle("Ghost role", isOn: $viewModel.ghostEnabled)
                    Toggle("Show role on card", isOn: $viewModel.showRoleOnCard)

                    Picker("Distribution", selection: $viewModel.distributionMode) {
                        ForEach(DistributionMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                }
                .frame(height: 220)

                HStack {
                    TextField("Player name", text: $viewModel.newPlayerName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { viewModel.addPlayer() }

                    Button("Add") {
                        viewModel.addPlayer()
                    }
                    .disabled(!viewModel.canAddPlayer)
                }

                if viewModel.playerNames.isEmpty {
                    Text("Add at least 4 players to continue.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.secondaryLabel)
                } else {
                    List {
                        ForEach(viewModel.playerNames, id: \.self) { name in
                            HStack {
                                AvatarView(name: name, color: .gray, size: 36)
                                Text(name)
                            }
                        }
                        .onDelete(perform: viewModel.removePlayer)
                    }
                    .listStyle(.plain)
                    .frame(minHeight: 160)
                }

                PrimaryButton(title: "Distribute Roles") {
                    viewModel.distributeRolesTapped()
                }
                .disabled(!viewModel.canContinue)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(AppTypography.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Lobby")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LobbyView(viewModel: LobbyViewModel(dependencies: AppDependencies()))
    }
}
