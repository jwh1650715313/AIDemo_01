import Foundation

// 当前阶段的假数据仓库。
// 真实项目里这里通常会换成网络请求。
final class StubAuthRepository: AuthRepository {
    private let validEmail = "15071126613@163.com"
    private let validPassword = "123456"

    func login(email: String, password: String) async throws -> UserSession {
        // 模拟真实网络请求的延迟，让 loading 状态能看出来。
        try await Task.sleep(for: .milliseconds(600))

        // 这里只允许指定账号密码通过，方便演示完整登录流程。
        guard email == validEmail, password == validPassword else {
            throw LoginError.invalidCredentials
        }

        return UserSession(
            email: email,
            welcomeMessage: "\(email) 登录成功，欢迎进入首页。"
        )
    }
}
