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
}
