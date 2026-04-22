//
//  SceneDelegate.swift
//  AIDemo_01
//
//  Created by kwmin on 2026/4/21.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    // window 是当前 scene 的根窗口。
    var window: UIWindow?
    // coordinator 必须持有住，不然启动后就会被释放。
    var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // SceneDelegate 只负责把 window 和 coordinator 接起来，
        // 真正的页面流转逻辑全部交给 AppCoordinator。
        let window = UIWindow(windowScene: windowScene)
        let appCoordinator = AppCoordinator(window: window)
        appCoordinator.start()

        self.appCoordinator = appCoordinator
        self.window = window
    }
}
