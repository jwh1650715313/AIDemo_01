import Foundation

// 登录态存储协议。
// 后面如果想从 UserDefaults 换成 Keychain 或数据库，只需要换实现，不用改上层逻辑。
protocol SessionStore {
    func loadSession() -> UserSession?
    func saveSession(_ session: UserSession)
    func clearSession()
}

// 当前最简单的实现：把登录态序列化后存到 UserDefaults。
final class UserDefaultsSessionStore: SessionStore {
    private enum Keys {
        static let userSession = "user_session"
    }

    private let userDefaults: UserDefaults
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSession() -> UserSession? {
        // 先从本地取 Data，再解码成 UserSession。
        guard let data = userDefaults.data(forKey: Keys.userSession) else {
            return nil
        }

        return try? decoder.decode(UserSession.self, from: data)
    }

    func saveSession(_ session: UserSession) {
        // 登录成功后把会话对象编码并持久化。
        guard let data = try? encoder.encode(session) else {
            return
        }

        userDefaults.set(data, forKey: Keys.userSession)
    }

    func clearSession() {
        // 退出登录时把本地登录态直接清掉。
        userDefaults.removeObject(forKey: Keys.userSession)
    }
}
