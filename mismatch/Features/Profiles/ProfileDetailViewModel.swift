import Foundation

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
