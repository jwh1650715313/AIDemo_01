import Foundation

// 聊天消息的发送方，UI 会根据发送方决定左右布局。
enum ChatMessageSender: Hashable {
    case ai
    case user
}

// 消息内容类型：普通文本和 AI 正在输入两种状态。
enum ChatMessageContent: Hashable {
    case text(String)
    case typing
}

// 聊天列表使用的轻量模型，UI 层只关心展示，不关心消息来自本地还是 API。
struct ChatMessage: Hashable {
    let id: UUID
    let sender: ChatMessageSender
    let content: ChatMessageContent
    let time: String
    let isRead: Bool

    init(
        id: UUID = UUID(),
        sender: ChatMessageSender,
        content: ChatMessageContent,
        time: String,
        isRead: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.content = content
        self.time = time
        self.isRead = isRead
    }

    init(sender: ChatMessageSender, text: String, time: String, isRead: Bool = false) {
        self.init(
            sender: sender,
            content: .text(text),
            time: time,
            isRead: isRead
        )
    }

    var text: String {
        guard case let .text(value) = content else { return "" }
        return value
    }

    var isTyping: Bool {
        if case .typing = content {
            return true
        }
        return false
    }
}

extension ChatMessage {
    static let welcomeMessages: [ChatMessage] = [
        ChatMessage(
            sender: .ai,
            text: """
            你好！我是灵境 AI。
            现在已经接入豆包 API，可以直接开始聊天。
            """,
            time: "09:41"
        )
    ]
}
