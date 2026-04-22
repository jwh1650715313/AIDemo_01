import Foundation

// 登录页的状态管理中心。
// 它接收页面输入，处理业务结果，再把状态和路由事件回传给页面。
final class LoginViewModel {
    var onStateChange: ((LoginViewState) -> Void)?
    var onRoute: ((LoginRoute) -> Void)?

    private let useCase: LoginUseCase
    private var state = LoginViewState() {
        didSet {
            // 只要状态变化，就立刻通知页面刷新。
            onStateChange?(state)
        }
    }

    init(useCase: LoginUseCase) {
        self.useCase = useCase
    }

    func viewDidLoad() {
        // 页面首次进来时，先把默认状态同步给 View。
        onStateChange?(state)
    }

    func updateEmail(_ email: String) {
        state.email = email
        state.errorMessage = nil
    }

    func updatePassword(_ password: String) {
        state.password = password
        state.errorMessage = nil
    }

    func loginTapped() {
        guard !state.isLoading else { return }

        // 先把当前输入快照下来，避免异步过程中被用户继续修改造成混乱。
        let email = state.email
        let password = state.password
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let session = try await useCase.execute(email: email, password: password)
                await MainActor.run {
                    state.isLoading = false
                    // 登录成功后不在这里直接跳页面，只抛出一个路由事件。
                    onRoute?(.loginSuccess(session))
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    // 错误信息回到状态里，由页面决定怎么展示。
                    state.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func forgotPasswordTapped() {
        onRoute?(.forgotPassword)
    }

    func appleSignInTapped() {
        onRoute?(.appleSignIn)
    }
}
