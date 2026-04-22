import UIKit

// “我的”模块。
// 这里除了展示当前账号信息，还提供退出登录入口。
final class ProfileViewController: UIViewController {
    private let session: UserSession
    // 退出登录本身不在页面里直接处理，而是交给上层 coordinator/app flow。
    private let onLogout: () -> Void

    init(session: UserSession, onLogout: @escaping () -> Void) {
        self.session = session
        self.onLogout = onLogout
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "我的"
        view.backgroundColor = .systemGroupedBackground
        configureLayout()
    }

    private func configureLayout() {
        // 当前页面先用一张卡片承载账号信息和退出按钮。
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 20

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.text = "我的"

        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.numberOfLines = 0
        infoLabel.font = .systemFont(ofSize: 16, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.text = "登录账号：\(session.email)\n这里后面可以继续扩展个人信息、设置等模块。"

        let logoutButton = UIButton(type: .system)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("退出登录", for: .normal)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        logoutButton.backgroundColor = UIColor.systemRed
        logoutButton.layer.cornerRadius = 14
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)

        view.addSubview(cardView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(infoLabel)
        cardView.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            cardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),

            infoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            
            logoutButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            logoutButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            logoutButton.heightAnchor.constraint(equalToConstant: 52),
            logoutButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }

    @objc
    private func logoutTapped() {
        // 退出登录属于高风险动作，先让用户确认一遍。
        let alert = UIAlertController(
            title: "退出登录",
            message: "确认退出当前账号吗？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(
            UIAlertAction(title: "退出", style: .destructive) { [weak self] _ in
                self?.onLogout()
            }
        )
        present(alert, animated: true)
    }
}
