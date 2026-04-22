import UIKit

// 依赖装配器。
// 这个文件不写业务逻辑，只负责“谁依赖谁”。
final class AppDependencyContainer {
    private lazy var sessionStore: SessionStore = UserDefaultsSessionStore()

    func makeLoginCoordinator(
        navigationController: UINavigationController,
        onLoginSuccess: @escaping (UserSession) -> Void
    ) -> LoginCoordinator {
        // Coordinator 只负责路由，所以这里只把它需要的依赖传进去。
        LoginCoordinator(
            navigationController: navigationController,
            makeLoginViewController: makeLoginViewController,
            onLoginSuccess: onLoginSuccess
        )
    }

    func makeLoginViewController() -> LoginViewController {
        // 登录页这条链路是：
        // ViewController -> ViewModel -> UseCase -> Repository
        let repository = makeAuthRepository()
        let useCase = LoginUseCase(repository: repository)
        let viewModel = LoginViewModel(useCase: useCase)
        return LoginViewController(viewModel: viewModel)
    }

    private func makeAuthRepository() -> AuthRepository {
        StubAuthRepository()
    }

    func makeSessionStore() -> SessionStore {
        sessionStore
    }

    func makeHomeTabBarController(
        session: UserSession,
        onLogout: @escaping () -> Void
    ) -> UITabBarController {
        let controller = UITabBarController()

        // 首页和我的都拿到当前登录用户信息，
        // “我的”页面额外拿到一个退出登录的回调。
        let homeViewController = HomeViewController(session: session)
        let profileViewController = ProfileViewController(session: session, onLogout: onLogout)

        let homeNavigationController = UINavigationController(rootViewController: homeViewController)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)

        homeNavigationController.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house.fill"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        profileNavigationController.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )

        controller.viewControllers = [homeNavigationController, profileNavigationController]
        return controller
    }
}
