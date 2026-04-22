import UIKit

// 登录页控制器。
// 它负责把 View 和 ViewModel 接起来，但不直接写登录业务。
final class LoginViewController: UIViewController {
    // 页面不直接跳转，而是把路由事件往外抛给 Coordinator。
    var onRoute: ((LoginRoute) -> Void)?

    private let contentView = LoginView()
    private let viewModel: LoginViewModel

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        bindActions()
        viewModel.viewDidLoad()
    }

    private func bindViewModel() {
        // ViewModel 一旦状态变化，页面就根据新状态刷新 UI。
        viewModel.onStateChange = { [weak self] state in
            self?.contentView.render(state: state)

            if let message = state.errorMessage {
                self?.showError(message)
            }
        }

        viewModel.onRoute = { [weak self] route in
            self?.onRoute?(route)
        }
    }

    private func bindActions() {
        // 所有用户交互都在控制器层统一绑定，再转发给 ViewModel。
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        contentView.emailField.addTarget(self, action: #selector(emailChanged), for: .editingChanged)
        contentView.passwordField.addTarget(self, action: #selector(passwordChanged), for: .editingChanged)
        contentView.loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        contentView.appleButton.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        contentView.forgotButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
    }

    private func showError(_ message: String) {
        guard presentedViewController == nil else { return }

        // 当前错误提示先用弹窗，后面也可以替换成页面内提示。
        let alert = UIAlertController(
            title: "登录失败",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "我知道了", style: .default))
        present(alert, animated: true)
    }

    @objc
    private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc
    private func emailChanged() {
        viewModel.updateEmail(contentView.emailField.text ?? "")
    }

    @objc
    private func passwordChanged() {
        viewModel.updatePassword(contentView.passwordField.text ?? "")
    }

    @objc
    private func loginTapped() {
        // 点登录前先收起键盘，避免遮挡提示。
        dismissKeyboard()
        viewModel.loginTapped()
    }

    @objc
    private func appleSignInTapped() {
        viewModel.appleSignInTapped()
    }

    @objc
    private func forgotPasswordTapped() {
        viewModel.forgotPasswordTapped()
    }
}
