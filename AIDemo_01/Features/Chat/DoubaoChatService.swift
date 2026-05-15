import Foundation

// 聊天页依赖的回复能力。具体实现可以来自豆包，也可以在测试里换成假服务。
protocol ChatResponding {
    func reply(for messages: [ChatMessage]) async throws -> String
}

final class DoubaoChatService: ChatResponding {
    private let urlSession: URLSession
    private let configurationProvider: () throws -> DoubaoChatConfiguration
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        urlSession: URLSession = .shared,
        configurationProvider: @escaping () throws -> DoubaoChatConfiguration = DoubaoChatConfiguration.loadFromBundle
    ) {
        self.urlSession = urlSession
        self.configurationProvider = configurationProvider
    }

    func reply(for messages: [ChatMessage]) async throws -> String {
        let configuration = try configurationProvider()
        let requestMessages = makeRequestMessages(from: messages)
        let payload = DoubaoChatCompletionRequest(
            model: configuration.model,
            messages: requestMessages
        )

        var request = URLRequest(url: configuration.chatCompletionsURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DoubaoChatServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw DoubaoChatServiceError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: parseErrorMessage(from: data) ?? "请求失败"
            )
        }

        let completion = try decoder.decode(DoubaoChatCompletionResponse.self, from: data)
        let answer = completion.choices
            .compactMap { $0.message.content }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !answer.isEmpty else {
            throw DoubaoChatServiceError.missingAnswer
        }

        return answer
    }

    private func makeRequestMessages(from messages: [ChatMessage]) -> [DoubaoChatRequestMessage] {
        var requestMessages = [
            DoubaoChatRequestMessage(
                role: "system",
                content: "你是灵境 AI，一个友好、简洁、可靠的中文聊天助手。"
            )
        ]

        let conversationMessages = messages.compactMap { message -> DoubaoChatRequestMessage? in
            guard case let .text(text) = message.content else { return nil }

            switch message.sender {
            case .ai:
                return DoubaoChatRequestMessage(role: "assistant", content: text)
            case .user:
                return DoubaoChatRequestMessage(role: "user", content: text)
            }
        }

        requestMessages.append(contentsOf: conversationMessages)
        return requestMessages
    }

    private func parseErrorMessage(from data: Data) -> String? {
        if let envelope = try? decoder.decode(DoubaoErrorEnvelope.self, from: data) {
            if let message = envelope.error?.message, !message.isEmpty {
                return message
            }

            if let message = envelope.message, !message.isEmpty {
                return message
            }

            if let code = envelope.code, !code.isEmpty {
                return code
            }
        }

        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct DoubaoChatConfiguration {
    private static let defaultChatCompletionsURLString = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    private static let defaultModel = "doubao-seed-character-251128"

    let chatCompletionsURL: URL
    let apiKey: String
    let model: String

    static func loadFromBundle() throws -> DoubaoChatConfiguration {
        guard let apiKey = configuredValue(for: "ARK_API_KEY") else {
            throw DoubaoChatServiceError.missingAPIKey
        }

        let urlString = configuredValue(for: "ARK_CHAT_COMPLETIONS_URL") ?? defaultChatCompletionsURLString
        guard let url = URL(string: urlString) else {
            throw DoubaoChatServiceError.invalidEndpoint(urlString)
        }

        return DoubaoChatConfiguration(
            chatCompletionsURL: url,
            apiKey: apiKey,
            model: configuredValue(for: "ARK_MODEL") ?? defaultModel
        )
    }

    private static func configuredValue(for key: String) -> String? {
        let bundleValue = Bundle.main.object(forInfoDictionaryKey: key) as? String
        let environmentValue = ProcessInfo.processInfo.environment[key]

        return [bundleValue, environmentValue]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { value in
                !value.isEmpty
                    && !value.contains("$(")
                    && !value.localizedCaseInsensitiveContains("YOUR_")
            }
    }
}

private struct DoubaoChatCompletionRequest: Encodable {
    let model: String
    let messages: [DoubaoChatRequestMessage]
}

private struct DoubaoChatRequestMessage: Encodable {
    let role: String
    let content: String
}

private struct DoubaoChatCompletionResponse: Decodable {
    let choices: [DoubaoChoice]
}

private struct DoubaoChoice: Decodable {
    let message: DoubaoResponseMessage
}

private struct DoubaoResponseMessage: Decodable {
    let content: String?
}

private struct DoubaoErrorEnvelope: Decodable {
    let error: DoubaoAPIError?
    let code: String?
    let message: String?
}

private struct DoubaoAPIError: Decodable {
    let message: String?
}

enum DoubaoChatServiceError: LocalizedError {
    case missingAPIKey
    case invalidEndpoint(String)
    case invalidResponse
    case missingAnswer
    case requestFailed(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "没有找到 ARK_API_KEY，请在 AIDemo_01/Config/LocalSecrets.xcconfig 或 Xcode Scheme 环境变量中配置。"
        case let .invalidEndpoint(urlString):
            return "豆包接口地址无效：\(urlString)"
        case .invalidResponse:
            return "豆包服务响应格式无效。"
        case .missingAnswer:
            return "豆包响应里没有可展示的回答。"
        case let .requestFailed(statusCode, message):
            return "豆包请求失败（HTTP \(statusCode)）：\(message)"
        }
    }
}
