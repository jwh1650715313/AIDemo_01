import UIKit

// 整个 App 的总导演。
// 它负责启动页、登录页和首页之间的页面流转。
final class AppCoordinator {
    // window 是 iOS App 真正承载页面的根容器。
    private let window: UIWindow
    // 登录流使用导航控制器承载，后面如果登录页有更多跳转会比较方便。
    private let navigationController: UINavigationController
    // 依赖装配器，专门负责把页面、ViewModel、Repository 这些对象拼起来。
    private let dependencyContainer: AppDependencyContainer
    // 登录态存储器，负责从本地读取、保存、清空登录信息。
    private let sessionStore: SessionStore
    private var loginCoordinator: LoginCoordinator?

    init(
        window: UIWindow,
        navigationController: UINavigationController = UINavigationController(),
        dependencyContainer: AppDependencyContainer = AppDependencyContainer()
    ) {
        self.window = window
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
        self.sessionStore = dependencyContainer.makeSessionStore()
    }
    
    func start() {
        showSplash()
        window.makeKeyAndVisible()
    }

    private func showSplash() {
        let splashViewController = SplashViewController { [weak self] in
            self?.showInitialScreen()
        }
        window.rootViewController = splashViewController
    }

    private func showInitialScreen() {
        // Splash 结束后再看本地有没有登录态。
        // 有就进首页，没有就从登录页开始。
        if let session = sessionStore.loadSession() {
            showHome(session: session)
        } else {
            showLogin()
        }
    }

    private func showLogin() {
        // 登录页不需要导航栏，所以先隐藏。
        navigationController.setNavigationBarHidden(true, animated: false)

        let loginCoordinator = dependencyContainer.makeLoginCoordinator(
            navigationController: navigationController,
            onLoginSuccess: { [weak self] session in
                // 登录成功时先把会话保存到本地，再切到首页。
                self?.sessionStore.saveSession(session)
                self?.showHome(session: session)
            }
        )
        loginCoordinator.start()
        self.loginCoordinator = loginCoordinator

        setRootViewController(navigationController)
    }

    private func showHome(session: UserSession) {
        // 首页使用 TabBar 承载多个模块。
        let homeTabBarController = dependencyContainer.makeHomeTabBarController(
            session: session,
            onLogout: { [weak self] in
                // 退出登录时必须先清掉本地登录态，不然重启 App 还会自动进首页。
                self?.sessionStore.clearSession()
                self?.showLogin()
            }
        )
        homeTabBarController.modalPresentationStyle = .fullScreen
        loginCoordinator = nil
        setRootViewController(homeTabBarController)
    }

    private func setRootViewController(_ viewController: UIViewController) {
        guard window.rootViewController != nil else {
            window.rootViewController = viewController
            return
        }

        UIView.transition(
            with: window,
            duration: 0.35,
            options: [.transitionCrossDissolve, .allowAnimatedContent]
        ) {
            self.window.rootViewController = viewController
        }
    }
}
