import SwiftUI

enum AppRoute: Hashable {
    case lobby
    case passThePhone
    case qrGrid
    case discussion
    case voting
    case results
    case sessionSummary
    case profiles
}

@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()
    private(set) var currentRoute: AppRoute?

    func navigate(to route: AppRoute) {
        path.append(route)
        currentRoute = route
    }

    func replaceWithSessionSummary() {
        show(.sessionSummary)
    }

    func replaceWithDistribution(_ route: AppRoute) {
        show(route)
    }

    func popToRoot() {
        path = NavigationPath()
        currentRoute = nil
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
        currentRoute = nil
    }

    func replaceWithLobby() {
        show(.lobby)
    }

    /// Replaces the whole stack in one update. Clearing the path and then appending
    /// lets SwiftUI pop back through the lobby before the new screen is applied.
    private func show(_ route: AppRoute) {
        var next = NavigationPath()
        next.append(route)
        path = next
        currentRoute = route
    }

    func popLast(_ count: Int) {
        guard count > 0 else { return }
        let removeCount = min(count, path.count)
        for _ in 0..<removeCount {
            path.removeLast()
        }
    }

    func continueToDiscussion() {
        popLast(3)
        path.append(AppRoute.discussion)
        currentRoute = .discussion
    }
}
