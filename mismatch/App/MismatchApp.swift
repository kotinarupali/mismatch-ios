import SwiftUI
import SwiftData

@main
struct MismatchApp: App {
    private let modelContainer: ModelContainer
    @State private var dependencies: AppDependencies

    init() {
        do {
            let container = try SwiftDataContainer.makeProduction()
            modelContainer = container
            _dependencies = State(initialValue: AppDependencies(modelContainer: container))
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: dependencies)
        }
        .modelContainer(modelContainer)
    }
}
