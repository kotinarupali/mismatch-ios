import Foundation

struct CustomWordPackStore: Sendable {
    private let defaults: UserDefaults
    private let key = "customWordPackLibrary"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> CustomPackLibrary {
        guard let data = defaults.data(forKey: key),
              let library = try? JSONDecoder().decode(CustomPackLibrary.self, from: data) else {
            return .empty
        }
        return library
    }

    func save(_ library: CustomPackLibrary) {
        guard let data = try? JSONEncoder().encode(library) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
