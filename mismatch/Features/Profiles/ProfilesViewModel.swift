import Foundation

@MainActor
@Observable
final class ProfilesViewModel {
    private let dependencies: AppDependencies

    var profiles: [PlayerProfile] = []
    var errorMessage: String?
    var showCreateProfile = false
    var newProfileName = ""
    var newProfileColor: AvatarColor = .blue

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func onAppear() {
        reload()
    }

    func reload() {
        do {
            profiles = try dependencies.profileRepository.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load profiles."
        }
    }

    func openCreateProfile() {
        newProfileName = ""
        newProfileColor = AvatarColor.forIndex(profiles.count)
        showCreateProfile = true
    }

    func createProfile() {
        let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            _ = try dependencies.profileRepository.create(name: trimmed, avatarColor: newProfileColor)
            showCreateProfile = false
            reload()
        } catch {
            errorMessage = "Could not create profile."
        }
    }

    func deleteProfile(id: UUID) {
        do {
            try dependencies.profileRepository.delete(id: id)
            reload()
        } catch {
            errorMessage = "Could not delete profile."
        }
    }

    func detailViewModel(for profileId: UUID) -> ProfileDetailViewModel {
        ProfileDetailViewModel(dependencies: dependencies, profileId: profileId)
    }
}

@MainActor
@Observable
final class ProfileDetailViewModel {
    private let dependencies: AppDependencies
    let profileId: UUID

    var profile: PlayerProfile?
    var draftName = ""
    var draftColor: AvatarColor = .blue
    var errorMessage: String?

    init(dependencies: AppDependencies, profileId: UUID) {
        self.dependencies = dependencies
        self.profileId = profileId
    }

    func onAppear() {
        reload()
    }

    func reload() {
        do {
            guard let loaded = try dependencies.profileRepository.fetch(id: profileId) else {
                errorMessage = "Profile not found."
                return
            }
            profile = loaded
            draftName = loaded.name
            draftColor = loaded.avatarColor
            errorMessage = nil
        } catch {
            errorMessage = "Could not load profile."
        }
    }

    func saveChanges() {
        do {
            try dependencies.profileRepository.update(
                id: profileId,
                name: draftName,
                avatarColor: draftColor
            )
            reload()
        } catch {
            errorMessage = "Could not save profile."
        }
    }

    func deleteProfile() {
        try? dependencies.profileRepository.delete(id: profileId)
    }
}
