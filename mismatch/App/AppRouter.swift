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
}
