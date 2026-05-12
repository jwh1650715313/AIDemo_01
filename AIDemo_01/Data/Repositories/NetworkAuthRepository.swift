import Foundation
import Alamofire

final class NetworkAuthRepository: AuthRepository {
    private let loginURL: URL
    private let session: Session
    private let decoder = JSONDecoder()

    init(
        loginURL: URL = URL(string: "https://lingjingai.online/api/login")!,
        session: Session = .default
    ) {
        self.loginURL = loginURL
        self.session = session
    }

    func login(email: String, password: String) async throws -> UserSession {
        let payload = LoginRequest(username: email, password: password)

        let response = await session.request(
            loginURL,
            method: .post,
            parameters: payload,
            encoder: JSONParameterEncoder.default,
            headers: ["Content-Type": "application/json"],
            requestModifier: { request in
                request.timeoutInterval = 30
            }
        )
        .serializingData()
        .response

        guard let httpResponse = response.response else {
            if let error = response.error {
                throw NetworkAuthRepositoryError.requestFailed(error.localizedDescription)
            }
            throw NetworkAuthRepositoryError.invalidResponse
        }

        let data = response.data ?? Data()
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkAuthRepositoryError.requestFailed(
                parseMessage(from: data) ?? "登录失败（HTTP \(httpResponse.statusCode)）"
            )
        }

        if let error = response.error {
            throw NetworkAuthRepositoryError.requestFailed(error.localizedDescription)
        }

        guard let loginResponse = try? decoder.decode(LoginResponse.self, from: data) else {
            throw NetworkAuthRepositoryError.invalidResponse
        }

        guard loginResponse.code == 200 else {
            throw NetworkAuthRepositoryError.requestFailed(loginResponse.message)
        }

        printLoginSuccessResponse(data)

        let username = loginResponse.user?.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = username.flatMap { $0.isEmpty ? nil : $0 } ?? email
        let message = loginResponse.message.trimmingCharacters(in: .whitespacesAndNewlines)

        return UserSession(
            email: displayName,
            welcomeMessage: message.isEmpty ? "\(displayName) 登录成功，欢迎进入首页。" : message,
            token: loginResponse.token
        )
    }

    private func parseMessage(from data: Data) -> String? {
        if let response = try? decoder.decode(LoginResponse.self, from: data),
           !response.message.isEmpty {
            return response.message
        }

        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func printLoginSuccessResponse(_ data: Data) {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
           let prettyJSON = String(data: prettyData, encoding: .utf8) {
            print("登录接口成功返回：\n\(prettyJSON)")
            return
        }

        let responseText = String(data: data, encoding: .utf8) ?? "<无法解析为文本>"
        print("登录接口成功返回：\n\(responseText)")
    }
}

private struct LoginRequest: Encodable {
    let username: String
    let password: String
}

private struct LoginResponse: Decodable {
    let code: Int
    let message: String
    let token: String?
    let user: LoginUser?
}

private struct LoginUser: Decodable {
    let username: String
}

private enum NetworkAuthRepositoryError: LocalizedError {
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "登录服务响应格式无效。"
        case let .requestFailed(message):
            return message
        }
    }
}
