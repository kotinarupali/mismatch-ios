import Foundation

@MainActor
@Observable
final class ProfilesViewModel {
    private let dependencies: AppDependencies

    var profiles: [PlayerProfile] = []
    var errorMessage: String?

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
