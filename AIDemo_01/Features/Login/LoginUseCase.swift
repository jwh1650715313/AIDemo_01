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
        // UI 已改为手机号登录。这里暂时沿用 email 参数名，避免扩大改动范围。
        let normalizedPhone = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedPhone.range(of: #"^1\d{10}$"#, options: .regularExpression) != nil else {
            throw LoginError.invalidPhone
        }

        guard password.count >= 6 else {
            throw LoginError.invalidPassword
        }

        // 真正执行登录。
        return try await repository.login(email: normalizedPhone, password: password)
    }
}
