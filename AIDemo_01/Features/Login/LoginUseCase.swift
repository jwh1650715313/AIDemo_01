import Foundation

// Repository 协议代表“登录能力”，不关心底层到底来自网络还是本地假数据。
protocol AuthRepository {
    func login(email: String, password: String) async throws -> UserSession
}

// UseCase 负责真正的登录规则。
// 简单理解：登录前先做业务校验，校验通过后再交给 Repository。
final class LoginUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String) async throws -> UserSession {
        // 先清掉邮箱两端空格，避免用户复制账号时多带了空格。
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedEmail.contains("@"), normalizedEmail.contains(".") else {
            throw LoginError.invalidEmail
        }

        guard password.count >= 6 else {
            throw LoginError.invalidPassword
        }

        // 真正执行登录。
        return try await repository.login(email: normalizedEmail, password: password)
    }
}
