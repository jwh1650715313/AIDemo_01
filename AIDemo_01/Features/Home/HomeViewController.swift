import UIKit

// 首页模块。
// 现在先放一个最小可用页面，后面可以继续往里扩展真实业务卡片和模块。
final class HomeViewController: UIViewController {
    private let session: UserSession

    init(session: UserSession) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "首页"
        view.backgroundColor = .systemBackground
        configureLayout()
        runQwenChatDemo()
    }

    private func configureLayout() {
        // 当前首页先展示最核心的信息：这是首页，以及当前登录的是谁。
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.text = "首页"

        let welcomeLabel = UILabel()
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.numberOfLines = 0
        welcomeLabel.font = .systemFont(ofSize: 16, weight: .regular)
        welcomeLabel.textColor = .secondaryLabel
        welcomeLabel.text = "当前登录账号：\(session.email)\n只有登录成功后才能进入这个页面。"

        let stackView = UIStackView(arrangedSubviews: [titleLabel, welcomeLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 12

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32)
        ])
    }

    private func runQwenChatDemo() {
        Task {
            let question = "用一句中文介绍一下你自己。 来一首诗"

            do {
                let answer = try await requestQwenAnswer(question: question)
                print("千问 问：\(question)")
                print("千问 答：\(answer)")
            } catch {
                print("千问请求失败：\(error.localizedDescription)")
            }
        }
    }

    private func requestQwenAnswer(question: String) async throws -> String {
        guard let apiKey = QwenConfiguration.apiKey else {
            throw QwenChatError.missingAPIKey
        }

        let url = URL(string: QwenConfiguration.chatCompletionsURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": QwenConfiguration.model,
            "messages": [
                [
                    "role": "system",
                    "content": "你是一个友好、简洁的中文助手。"
                ],
                [
                    "role": "user",
                    "content": question
                ]
            ]
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QwenChatError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw QwenChatError.requestFailed(message)
        }

        return try QwenResponseParser.answerText(from: data)
    }
}

private enum QwenConfiguration {
    static let chatCompletionsURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    static let model = "qwen-plus"

    static var apiKey: String? {
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "DASHSCOPE_API_KEY") as? String
        let environmentValue = ProcessInfo.processInfo.environment["DASHSCOPE_API_KEY"]

        return [infoValue, environmentValue]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.hasPrefix("$(") }
    }
}

private enum QwenResponseParser {
    static func answerText(from data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let choices = json?["choices"] as? [[String: Any]] else {
            throw QwenChatError.missingAnswer
        }

        let textParts = choices.compactMap { choice -> String? in
            guard let message = choice["message"] as? [String: Any] else {
                return nil
            }
            return message["content"] as? String
        }

        let answer = textParts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !answer.isEmpty else {
            throw QwenChatError.missingAnswer
        }

        return answer
    }
}

private enum QwenChatError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case missingAnswer
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "没有找到 DASHSCOPE_API_KEY，请在 Xcode Scheme 的环境变量或 Info.plist 对应配置里设置。"
        case .invalidResponse:
            return "服务端响应格式无效。"
        case .missingAnswer:
            return "响应里没有解析到回答文本。"
        case let .requestFailed(message):
            return message
        }
    }
}
