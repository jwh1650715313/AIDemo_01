import UIKit

// 登录流程的路由控制器。
// 它不做登录逻辑，只负责“登录页下一步该跳去哪”。
final class LoginCoordinator {
    private let navigationController: UINavigationController
    private let makeLoginViewController: () -> LoginViewController
    private let onLoginSuccess: (UserSession) -> Void

    init(
        navigationController: UINavigationController,
        makeLoginViewController: @escaping () -> LoginViewController,
        onLoginSuccess: @escaping (UserSession) -> Void
    ) {
        self.navigationController = navigationController
        self.makeLoginViewController = makeLoginViewController
        self.onLoginSuccess = onLoginSuccess
    }

    func start() {
        // 登录流的起点就是登录页。
        let viewController = makeLoginViewController()
        bindRoutes(for: viewController)
        navigationController.setViewControllers([viewController], animated: false)
    }

    private func bindRoutes(for viewController: LoginViewController) {
        viewController.onRoute = { [weak self] route in
            self?.handle(route: route)
        }
    }

    private func handle(route: LoginRoute) {
        // ViewModel 只抛“路由事件”，真正怎么跳转由 Coordinator 决定。
        switch route {
        case .forgotPassword:
            presentAlert(
                title: "忘记密码",
                message: "这里后面可以接真实的找回密码流程。"
            )
        case .appleSignIn:
            presentAlert(
                title: "Apple 登录",
                message: "这里是 Apple 登录的入口，后面可以接入真实 SDK。"
            )
        case let .loginSuccess(session):
            onLoginSuccess(session)
        }
    }

    private func presentAlert(title: String, message: String) {
        guard let presenter = navigationController.topViewController else { return }

        // 这里先用弹窗占位，后面换成真实页面也只需要改 Coordinator。
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "知道了", style: .default))
        presenter.present(alert, animated: true)
    }
}
