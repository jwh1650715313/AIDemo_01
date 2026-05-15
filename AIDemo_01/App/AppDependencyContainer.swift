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
        NetworkAuthRepository()
    }

    private func makeChatService() -> ChatResponding {
        DoubaoChatService()
    }

    func makeSessionStore() -> SessionStore {
        sessionStore
    }

    func makeHomeTabBarController(
        session: UserSession,
        onLogout: @escaping () -> Void
    ) -> UITabBarController {
        let controller = UITabBarController()

        // 当前首页承载灵境 AI 聊天，真实回复由豆包 API 提供。
        // “我的”页面继续拿到当前登录用户信息和退出登录回调。
        let chatViewController = ChatViewController(
            chatService: makeChatService(),
            onLogout: onLogout
        )
        let profileViewController = ProfileViewController(session: session, onLogout: onLogout)

        let homeNavigationController = UINavigationController(rootViewController: chatViewController)
        let profileNavigationController = UINavigationController(rootViewController: profileViewController)

        homeNavigationController.tabBarItem = UITabBarItem(
            title: "灵境 AI",
            image: UIImage(systemName: "sparkles"),
            selectedImage: UIImage(systemName: "sparkles")
        )
        profileNavigationController.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.01, green: 0.03, blue: 0.09, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.42)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.42)
        ]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.20, green: 0.68, blue: 1.0, alpha: 1.0)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(red: 0.20, green: 0.68, blue: 1.0, alpha: 1.0)
        ]
        controller.tabBar.standardAppearance = tabBarAppearance
        controller.tabBar.scrollEdgeAppearance = tabBarAppearance

        controller.viewControllers = [homeNavigationController, profileNavigationController]
        return controller
    }
}
