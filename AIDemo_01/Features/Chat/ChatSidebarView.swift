import UIKit
import SnapKit

// 简单版 AI 聊天侧边栏：只负责展示和按钮事件，不写真实聊天列表业务。
final class ChatSidebarView: UIView {
    var onNewChatTap: (() -> Void)?
    var onAllChatsTap: (() -> Void)?
    var onSettingsTap: (() -> Void)?
    var onLogoutTap: (() -> Void)?

    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
    private let tintView = UIView()
    private let edgeGlowView = UIView()

    private let contentStack = UIStackView()
    private let headerStack = UIStackView()
    private let titleStack = UIStackView()
    private let logoView = ChatSidebarLogoView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let menuCardView = UIView()
    private let menuStack = UIStackView()
    private let spacerView = UIView()

    private lazy var newChatButton = makeMenuButton(
        title: "新建聊天",
        systemName: "plus",
        tintColor: .white,
        action: #selector(newChatTapped)
    )
    private lazy var allChatsButton = makeMenuButton(
        title: "所有聊天",
        systemName: "bubble.left.and.bubble.right",
        tintColor: .white,
        action: #selector(allChatsTapped)
    )
    private lazy var settingsButton = makeMenuButton(
        title: "设置",
        systemName: "gearshape",
        tintColor: .white,
        action: #selector(settingsTapped)
    )
    private lazy var logoutButton = makeMenuButton(
        title: "退出登录",
        systemName: "rectangle.portrait.and.arrow.right",
        tintColor: UIColor(red: 1.0, green: 0.26, blue: 0.20, alpha: 1.0),
        action: #selector(logoutTapped)
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureHeader()
        configureMenu()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        glowLayer.frame = CGRect(
            x: -bounds.width * 0.18,
            y: bounds.height * 0.10,
            width: bounds.width * 1.14,
            height: bounds.width * 1.14
        )
    }

    private func configureView() {
        backgroundColor = UIColor(red: 0.01, green: 0.04, blue: 0.12, alpha: 0.82)
        clipsToBounds = true
        layer.cornerRadius = 28
        layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]

        // 深蓝渐变打底，保持和聊天首页一致的科技感。
        gradientLayer.colors = [
            UIColor(red: 0.02, green: 0.08, blue: 0.19, alpha: 0.94).cgColor,
            UIColor(red: 0.04, green: 0.12, blue: 0.27, alpha: 0.86).cgColor,
            UIColor(red: 0.00, green: 0.02, blue: 0.08, alpha: 0.94).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.05, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.insertSublayer(gradientLayer, at: 0)

        // 柔和蓝色光晕，避免侧栏过于平。
        glowLayer.type = .radial
        glowLayer.colors = [
            UIColor(red: 0.05, green: 0.50, blue: 1.0, alpha: 0.26).cgColor,
            UIColor(red: 0.05, green: 0.50, blue: 1.0, alpha: 0.0).cgColor
        ]
        glowLayer.locations = [0.0, 1.0]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.insertSublayer(glowLayer, above: gradientLayer)

        tintView.backgroundColor = UIColor(red: 0.02, green: 0.06, blue: 0.14, alpha: 0.30)

        edgeGlowView.backgroundColor = UIColor(red: 0.20, green: 0.64, blue: 1.0, alpha: 0.18)
        edgeGlowView.layer.shadowColor = UIColor(red: 0.12, green: 0.56, blue: 1.0, alpha: 0.62).cgColor
        edgeGlowView.layer.shadowOpacity = 1
        edgeGlowView.layer.shadowRadius = 12
        edgeGlowView.layer.shadowOffset = .zero

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.alignment = .fill
    }

    private func configureHeader() {
        titleLabel.text = "灵境 AI"
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .white

        subtitleLabel.text = "你的智能伙伴"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.58)

        titleStack.axis = .vertical
        titleStack.spacing = 6
        titleStack.alignment = .leading

        headerStack.axis = .horizontal
        headerStack.spacing = 18
        headerStack.alignment = .center
    }

    private func configureMenu() {
        menuCardView.backgroundColor = UIColor(red: 0.07, green: 0.13, blue: 0.25, alpha: 0.68)
        menuCardView.layer.cornerRadius = 22
        menuCardView.layer.borderWidth = 1
        menuCardView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        menuCardView.layer.shadowColor = UIColor(red: 0.00, green: 0.30, blue: 0.72, alpha: 0.34).cgColor
        menuCardView.layer.shadowOpacity = 1
        menuCardView.layer.shadowRadius = 22
        menuCardView.layer.shadowOffset = CGSize(width: 0, height: 14)

        menuStack.axis = .vertical
        menuStack.spacing = 4

        logoutButton.backgroundColor = UIColor(red: 1.0, green: 0.18, blue: 0.15, alpha: 0.08)
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = UIColor(red: 1.0, green: 0.22, blue: 0.18, alpha: 0.16).cgColor
    }

    private func setupLayout() {
        addSubview(blurView)
        addSubview(tintView)
        addSubview(edgeGlowView)
        addSubview(contentStack)

        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subtitleLabel)
        headerStack.addArrangedSubview(logoView)
        headerStack.addArrangedSubview(titleStack)

        menuCardView.addSubview(menuStack)
        [newChatButton, allChatsButton, settingsButton].forEach(menuStack.addArrangedSubview)

        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(menuCardView)
        contentStack.addArrangedSubview(spacerView)
        contentStack.addArrangedSubview(logoutButton)
        contentStack.setCustomSpacing(44, after: headerStack)
        contentStack.setCustomSpacing(18, after: menuCardView)

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tintView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        edgeGlowView.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            make.width.equalTo(1)
        }

        // 内容跟随安全区，避免被状态栏和 Home Indicator 挡住。
        contentStack.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(30)
            make.leading.trailing.equalToSuperview().inset(22)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(24)
        }

        logoView.snp.makeConstraints { make in
            make.size.equalTo(64)
        }

        [newChatButton, allChatsButton, settingsButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(58)
            }
        }

        menuStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10))
        }

        logoutButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
    }

    private func makeMenuButton(
        title: String,
        systemName: String,
        tintColor: UIColor,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(
            systemName: systemName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        )
        configuration.imagePlacement = .leading
        configuration.imagePadding = 18
        configuration.baseForegroundColor = tintColor
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 16)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 17, weight: .medium)
            return outgoing
        }

        button.configuration = configuration
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func newChatTapped() {
        onNewChatTap?()
    }

    @objc private func allChatsTapped() {
        onAllChatsTap?()
    }

    @objc private func settingsTapped() {
        onSettingsTap?()
    }

    @objc private func logoutTapped() {
        onLogoutTap?()
    }
}

// 侧边栏顶部 AI Logo：渐变圆环 + 六边形图标，和聊天气泡头像保持同一视觉语言。
private final class ChatSidebarLogoView: UIView {
    private let outerGradientLayer = CAGradientLayer()
    private let innerView = UIView()
    private let iconImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        outerGradientLayer.frame = bounds
        outerGradientLayer.cornerRadius = bounds.height / 2
        innerView.layer.cornerRadius = innerView.bounds.height / 2
    }

    private func configureView() {
        clipsToBounds = false
        layer.shadowColor = UIColor(red: 0.00, green: 0.45, blue: 1.0, alpha: 0.50).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 18
        layer.shadowOffset = .zero

        outerGradientLayer.colors = [
            UIColor(red: 0.10, green: 0.66, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.05, green: 0.16, blue: 0.44, alpha: 1.0).cgColor
        ]
        outerGradientLayer.startPoint = CGPoint(x: 0.12, y: 0.0)
        outerGradientLayer.endPoint = CGPoint(x: 0.88, y: 1.0)
        layer.insertSublayer(outerGradientLayer, at: 0)

        innerView.backgroundColor = UIColor(red: 0.05, green: 0.14, blue: 0.29, alpha: 0.96)
        innerView.layer.borderWidth = 1
        innerView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        innerView.clipsToBounds = true

        iconImageView.image = UIImage(
            systemName: "hexagon.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold)
        )
        iconImageView.tintColor = UIColor(red: 0.70, green: 0.92, blue: 1.0, alpha: 1.0)
        iconImageView.contentMode = .scaleAspectFit
    }

    private func setupLayout() {
        addSubview(innerView)
        innerView.addSubview(iconImageView)

        innerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(30)
        }
    }
}
