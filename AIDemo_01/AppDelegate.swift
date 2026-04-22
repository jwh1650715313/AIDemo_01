import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // 这个项目的主要页面流转已经交给 SceneDelegate + AppCoordinator，
    // 所以 AppDelegate 目前只保留系统默认生命周期能力。
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // 当前 demo 没有需要主动释放的场景资源，这里先保留空实现。
    }
}
