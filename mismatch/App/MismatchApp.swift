import SwiftUI

@main
struct MismatchApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: dependencies)
        }
    }
}
