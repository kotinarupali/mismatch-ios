import SwiftUI

enum AppRoute: Hashable {
    case lobby
    case passThePhone
    case qrGrid
    case discussion
    case voting
    case results
}

@MainActor
@Observable
final class AppRouter {
    var path = NavigationPath()

    func navigate(to route: AppRoute) {
        path.append(route)
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func replaceWithLobby() {
        path = NavigationPath()
        path.append(AppRoute.lobby)
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
    }
}
