# 项目逻辑流程图

## 1. 项目现在做到了什么

当前 App 已经具备下面这条完整业务链：

- 启动先检查本地登录态
- 没登录时进入登录页
- 只有指定账号密码可以登录
- 登录成功后进入首页 TabBar
- 首页包含 `首页` 和 `我的` 两个模块
- 退出登录后会清掉本地登录态
- 下次启动会重新回到登录页

测试账号：

- 账号：`15071126613@163.com`
- 密码：`123456`

## 2. 启动流程

```text
App 启动
-> SceneDelegate
-> AppCoordinator.start()
-> 读取 SessionStore
-> 如果有登录态：进入首页
-> 如果没有登录态：进入登录页
```

### 对应代码

- [SceneDelegate.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/SceneDelegate.swift)
- [AppCoordinator.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/App/AppCoordinator.swift)
- [SessionStore.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Core/Storage/SessionStore.swift)

## 3. 登录流程

```text
LoginViewController
-> 用户输入账号密码
-> LoginViewModel
-> LoginUseCase
-> StubAuthRepository
-> 校验账号密码
-> 成功后返回 UserSession
-> AppCoordinator 保存登录态
-> 进入首页 TabBar
```

### 登录职责拆分

#### LoginViewController

只负责：

- 展示 UI
- 监听按钮点击
- 把输入传给 ViewModel
- 监听状态变化并刷新界面

文件：

- [LoginViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginViewController.swift)

#### LoginView

只负责：

- 组装登录页 UI
- 控制输入框、按钮、布局
- 根据状态更新界面显示

文件：

- [LoginView.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginView.swift)

#### LoginViewModel

负责：

- 接收输入变化
- 管理登录状态
- 调用 UseCase
- 抛出页面路由事件

文件：

- [LoginViewModel.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginViewModel.swift)

#### LoginUseCase

负责：

- 校验邮箱格式
- 校验密码长度
- 调用 Repository 执行登录

文件：

- [LoginUseCase.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginUseCase.swift)

#### StubAuthRepository

负责：

- 当前阶段模拟登录接口
- 只允许指定账号密码通过

文件：

- [StubAuthRepository.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Data/Repositories/StubAuthRepository.swift)

## 4. 首页流程

登录成功后不会再停留在登录页，而是直接进入一个 `TabBarController`。

```text
AppCoordinator
-> makeHomeTabBarController()
-> 首页 HomeViewController
-> 我的 ProfileViewController
```

### 对应代码

- [AppDependencyContainer.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/App/AppDependencyContainer.swift)
- [HomeViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Home/HomeViewController.swift)
- [ProfileViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Profile/ProfileViewController.swift)

## 5. 退出登录流程

退出登录在“我的”页面完成。

```text
点击退出登录
-> ProfileViewController 弹确认框
-> 用户确认退出
-> AppCoordinator 收到 onLogout
-> SessionStore.clearSession()
-> 回到登录页
```

### 对应代码

- [ProfileViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Profile/ProfileViewController.swift)
- [AppCoordinator.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/App/AppCoordinator.swift)
- [SessionStore.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Core/Storage/SessionStore.swift)

## 6. 登录态持久化流程

当前登录态是存在 `UserDefaults` 里的。

```text
登录成功
-> SessionStore.saveSession()
-> UserDefaults 保存 UserSession

App 重启
-> SessionStore.loadSession()
-> 如果取到 UserSession
-> 直接进入首页

退出登录
-> SessionStore.clearSession()
-> 删除本地 UserSession
```

### 对应代码

- [SessionStore.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Core/Storage/SessionStore.swift)

## 7. 项目分层怎么理解

### App 层

负责应用入口、总路由、依赖装配。

包含：

- `SceneDelegate`
- `AppCoordinator`
- `AppDependencyContainer`

### Features 层

负责具体业务页面。

当前包含：

- `Login`
- `Home`
- `Profile`

### Data 层

负责数据来源。

当前包含：

- `StubAuthRepository`

### Core 层

负责通用基础能力。

当前包含：

- `SessionStore`

## 8. 一句话记住当前架构

你现在这个项目不是“页面直接调页面”，而是：

```text
页面管展示
ViewModel 管状态
UseCase 管业务
Repository 管数据
Coordinator 管跳转
SessionStore 管登录态
```

## 9. 最推荐你的阅读顺序

如果你想把现在这套代码完全看懂，建议按这个顺序读：

1. [SceneDelegate.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/SceneDelegate.swift)
2. [AppCoordinator.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/App/AppCoordinator.swift)
3. [AppDependencyContainer.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/App/AppDependencyContainer.swift)
4. [LoginViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginViewController.swift)
5. [LoginViewModel.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginViewModel.swift)
6. [LoginUseCase.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Login/LoginUseCase.swift)
7. [StubAuthRepository.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Data/Repositories/StubAuthRepository.swift)
8. [SessionStore.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Core/Storage/SessionStore.swift)
9. [HomeViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Home/HomeViewController.swift)
10. [ProfileViewController.swift](/Users/kwmin/Desktop/codeDemo/AIDemo_01/AIDemo_01/Features/Profile/ProfileViewController.swift)

## 10. 你下一步最适合继续做什么

如果要继续往正式项目推进，建议优先做这几件事：

- 把测试账号密码移到配置层
- 把 `StubAuthRepository` 替换成真实接口
- 给首页加真实业务模块
- 给“我的”页面加用户信息和设置
- 给登录态增加 token 过期机制
