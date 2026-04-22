import Foundation

// 登录成功后在 App 内流转的会话对象。
// 它被首页、“我的”页面和本地登录态持久化共同使用。
struct UserSession: Codable {
    let email: String
    let welcomeMessage: String
}

// 登录页可能抛出的路由事件。
enum LoginRoute {
    case forgotPassword
    case appleSignIn
    case loginSuccess(UserSession)
}

// 登录页状态。
// ViewController 不直接拼业务逻辑，而是根据这个状态决定页面怎么显示。
struct LoginViewState {
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    var isLoginButtonEnabled: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty && !isLoading
    }
}

// 登录过程中可能出现的业务错误。
enum LoginError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "请输入有效的邮箱地址。"
        case .invalidPassword:
            return "密码至少需要 6 位。"
        case .invalidCredentials:
            return "账号或密码错误，请使用指定测试账号登录。"
        }
    }
}
