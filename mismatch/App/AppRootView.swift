import SwiftUI

struct AppRootView: View {
    private let dependencies: AppDependencies
    @Bindable private var router: AppRouter

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _router = Bindable(dependencies.router)
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView(viewModel: HomeViewModel(dependencies: dependencies))
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .lobby:
                        LobbyView(viewModel: LobbyViewModel(dependencies: dependencies))
                    case .passThePhone:
                        PassThePhoneView(viewModel: PassThePhoneViewModel(dependencies: dependencies))
                    case .qrGrid:
                        QRGridView(viewModel: QRGridViewModel(dependencies: dependencies))
                    case .discussion:
                        DiscussionView(viewModel: DiscussionViewModel(dependencies: dependencies))
                    case .voting:
                        VotingView(viewModel: VotingViewModel(dependencies: dependencies))
                    case .results:
                        ResultsView(viewModel: ResultsViewModel(dependencies: dependencies))
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}
