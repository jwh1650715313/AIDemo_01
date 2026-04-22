# UIKit App 架构说明

## 1. 目标

这份文档用于定义一个适合 `Swift + UIKit` iOS App 的实用型架构方案。

目标不是一开始就堆很重的架构，而是让项目具备下面几个特点：

- 容易理解
- 容易迭代
- 容易测试
- 后续容易扩展

对于当前这个项目，推荐的方向是：

`UIKit + MVVM + Repository + 按业务拆分 Feature`

这套方案很适合中小型到中型项目，后续如果业务继续变大，也可以平滑演进成更完整的分层架构。

## 2. 核心原则

### 2.1 UI 和业务逻辑必须分离

`UIViewController` 主要负责：

- 组装界面
- 绑定数据
- 转发用户事件
- 处理页面生命周期

它不应该直接承担：

- 网络请求代码
- 本地存储代码
- 大段业务规则
- 第三方 SDK 调用细节

### 2.2 业务层不要直接依赖第三方库

第三方库可以用，但最好通过我们自己的抽象层进行隔离。

例如：

- 用 `NetworkClient`，不要在业务里到处直接调 `Alamofire`
- 用 `ImageLoader`，不要把图片库直接耦合到页面逻辑
- 用 `AnalyticsService`，不要在每个页面里直接调用埋点 SDK

这样做的好处是可替换、可测试、可维护。

### 2.3 目录优先按业务拆，不只按文件类型拆

不要只把所有控制器丢进 `Controllers`，所有模型丢进 `Models`，所有服务丢进 `Services`。

更推荐按业务模块拆分，例如：

- `Home`
- `Login`
- `Profile`
- `Settings`

每个 Feature 自己管理相关页面、ViewModel、Coordinator、UseCase 等代码。

### 2.4 数据流尽量保持单向

推荐的数据流：

`ViewController -> ViewModel -> UseCase / Repository -> DataSource / API / DB`

这样更容易定位问题，也能减少代码混乱。

## 3. 推荐分层

### 3.1 App 层

负责应用启动和全局装配。

典型内容：

- `AppDelegate`
- `SceneDelegate`
- 依赖注入容器
- 根 Coordinator
- 环境配置

### 3.2 Feature 层

负责具体业务页面和业务模块逻辑。

每个 Feature 可以包含：

- `ViewController`
- `View`
- `ViewModel`
- `Coordinator`
- `UseCase`
- 当前业务下的局部模型

### 3.3 Domain 层

负责稳定的业务概念和业务规则。

典型内容：

- `Entity`
- `UseCase`
- Repository 协议

这一层尽量不要依赖 UIKit，也不要依赖具体 SDK。

### 3.4 Data 层

负责数据组织和数据来源管理。

典型内容：

- Repository 实现
- Remote DataSource
- Local DataSource
- DTO 到 Entity 的映射

### 3.5 Core 层

负责项目级别的通用技术能力。

典型内容：

- 网络
- 存储
- 日志
- 埋点
- 通用 UI 组件
- 扩展
- 工具类

## 4. 推荐目录结构

```text
AIDemo_01
├── App
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── AppRouter.swift
│   ├── AppDependencyContainer.swift
│   └── Environment.swift
├── Features
│   ├── Login
│   │   ├── LoginViewController.swift
│   │   ├── LoginView.swift
│   │   ├── LoginViewModel.swift
│   │   ├── LoginCoordinator.swift
│   │   ├── LoginUseCase.swift
│   │   └── LoginModels.swift
│   ├── Home
│   └── Profile
├── Domain
│   ├── Entities
│   ├── UseCases
│   └── Repositories
├── Data
│   ├── Repositories
│   ├── Remote
│   ├── Local
│   └── Mappers
├── Core
│   ├── Networking
│   ├── Storage
│   ├── Analytics
│   ├── Logging
│   ├── UIComponents
│   ├── Extensions
│   └── Utils
└── Resources
    ├── Assets.xcassets
    ├── Base.lproj
    └── Config
```

## 5. Feature 内部结构

以 `Login` 模块为例：

### 5.1 `LoginViewController`

负责：

- 创建和布局 UI
- 绑定 `ViewModel` 输出
- 转发按钮点击和输入事件
- 根据状态展示 loading、error、success

应避免：

- 直接发请求
- 直接调 SDK
- 把复杂校验逻辑混在页面层

### 5.2 `LoginViewModel`

负责：

- 接收用户意图
- 调用 UseCase 或 Repository
- 整理页面状态
- 对外暴露 loading、content、error 等状态

典型职责：

- 输入校验
- 触发登录
- 控制登录按钮是否可点击
- 格式化页面展示数据

### 5.3 `LoginUseCase`

负责业务规则。

例如：

- 邮箱登录流程
- 密码校验规则
- token 刷新逻辑

如果某段逻辑未来可能被多个页面复用，就适合放在这一层。

### 5.4 `LoginCoordinator`

负责页面跳转和导航流转。

例如：

- 打开忘记密码页
- 登录成功后进入主页面
- 打开协议页或 Web 页面

导航逻辑不要散落在各个控制器里。

## 6. 数据流设计

推荐的请求流转：

```text
LoginViewController
  -> LoginViewModel
    -> LoginUseCase
      -> AuthRepository
        -> AuthRemoteDataSource
          -> NetworkClient
```

推荐的本地存储流转：

```text
ViewModel
  -> Repository
    -> LocalDataSource
      -> UserDefaults / Keychain / DB
```

这样职责会比较清晰：

- UI 层只关心界面和交互
- 业务层只关心规则和契约
- 数据层只关心数据来自哪里
- 基础设施层只关心技术实现方式

## 7. 第三方库接入规则

### 7.1 第三方库都尽量包一层

不要让 SDK 调用散落在业务代码里。

建议的封装位置：

- `Core/Networking/NetworkClient.swift`
- `Core/Storage/KeychainStore.swift`
- `Core/Analytics/AnalyticsService.swift`
- `Core/Image/ImageLoader.swift`

### 7.2 不同类型库放在哪一层

#### 网络库

例如：

- `Alamofire`
- 原生 `URLSession`

建议放在：

- `Core/Networking`

对外暴露：

- `NetworkClient`
- `APIRequest`
- `RequestInterceptor`

#### 图片加载

例如：

- `Kingfisher`
- `SDWebImage`

建议放在：

- `Core/UIComponents` 或 `Core/Image`

对外暴露：

- `ImageLoader`
- 必要时可以加 `RemoteImageView`

#### 数据库和缓存

例如：

- `Realm`
- `SQLite`

建议放在：

- `Data/Local`
- `Core/Storage`

关键原则：

- 数据库存储模型和业务实体模型要分开

#### 埋点和崩溃监控

例如：

- `Firebase Analytics`
- `Crashlytics`
- `Sentry`

建议放在：

- `Core/Analytics`
- `Core/Logging`

对外暴露：

- `AnalyticsService`
- `CrashReporting`

#### 登录、支付、地图、推送

例如：

- Apple 登录
- 微信 SDK
- Firebase
- 地图库

建议放在：

- `Core/Services`

对外暴露：

- `AuthService`
- `PaymentService`
- `MapService`
- `PushService`

## 8. 依赖注入策略

不要让控制器自己去构建所有下游依赖。

推荐做法：

- 用协议定义依赖能力
- 在 App 启动或 Coordinator 中完成装配
- 每个 Feature 只注入自己真正需要的依赖

简单例子：

```swift
protocol AuthRepository {
    func login(email: String, password: String) async throws -> User
}

final class LoginViewModel {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }
}
```

对早期项目来说，这种方式已经足够，不一定非要上 DI 框架。

## 9. 导航策略

对于 UIKit 项目，一旦页面流变多，建议使用 `Coordinator` 管理导航。

推荐结构：

- `AppCoordinator` 管理应用入口
- 各个 Feature Coordinator 管理自己的业务流

例如：

- `LoginCoordinator`
- `HomeCoordinator`
- `ProfileCoordinator`

好处：

- 控制器更轻
- 跳转逻辑更集中
- 更容易复用和测试

## 10. UI 搭建策略

当前项目可以选择：

- 纯代码 UI
- Storyboard 仅用于极小型页面

从可维护性角度，更推荐：

- 业务页面尽量使用纯代码 UI
- 通用组件沉淀到 `Core/UIComponents`

例如：

- `PrimaryButton`
- `InputFieldView`
- `LoadingView`
- `EmptyStateView`

这样更容易保持视觉统一，也能减少重复代码。

## 11. 状态管理建议

对于 UIKit，不建议一开始就把状态管理做得过重。

比较实用的方式是：

- `ViewModel` 持有 `State`
- `ViewController` 监听状态变化
- 页面根据状态渲染 UI

例如：

```swift
enum LoginViewState {
    case idle
    case loading
    case success
    case error(String)
}
```

这一层已经足够覆盖很多页面。

如果后面页面变复杂，再演进成更严格的单向数据流架构也不迟。

## 12. 测试策略

推荐的测试重点：

### 单元测试

优先覆盖：

- `ViewModel`
- `UseCase`
- `Repository`
- Mapper 逻辑

### UI 测试

适合覆盖：

- 登录流程
- 关键业务路径
- 基础 smoke test

测试原则：

- 业务逻辑尽量做到不依赖真实页面也能测试

## 13. 当前项目的演进建议

当前这个工程还比较接近 Xcode 默认模板，所以推荐下一步这样推进：

1. 把启动相关文件整理到 `App` 组
2. 把当前页面整理到 `Features/Login`
3. 将当前页面拆分成 `LoginViewController` 和 `LoginViewModel`
4. 增加一个最小可用的 `AppCoordinator`
5. 预留 `Core` 和 `Data` 组，为后续扩展做准备

第一阶段推荐结构：

```text
AIDemo_01
├── App
├── Features
│   └── Login
├── Core
└── Resources
```

这个阶段已经够用了，不需要一开始就过度设计。

## 14. 需要避免的事情

- 在 `UIViewController` 里直接写网络请求
- 页面里到处写跳转逻辑
- DTO、数据库模型、业务实体混成一个模型
- Feature 代码直接暴露第三方 SDK 调用
- 所有文件都平铺在一个目录里
- 业务还没起来就先堆太多抽象层

## 15. 最终建议

对于这个项目，目前最适合的起步方案是：

`UIKit + MVVM + Coordinator + Repository`

可以简化理解为：

- `UIViewController` 管界面
- `ViewModel` 管状态和交互
- `Coordinator` 管导航
- `Repository` 管数据访问
- `Core` 负责封装第三方能力和公共能力
- 整个项目按 `Feature` 拆分

这套方式足够清晰，也足够轻，适合当前阶段快速迭代。

等项目变大以后，再逐步补强：

- 更完整的 Domain 层
- 本地缓存策略
- 模块化 target
- 更严格的依赖注入和测试规范
