import UIKit

// 登录页纯视图。
// 它只关心怎么把页面画出来，不关心账号密码是否正确。
final class LoginView: UIView {
    let emailField = InsetTextField()
    let passwordField = InsetTextField()
    let forgotButton = UIButton(type: .system)
    let loginButton = UIButton(type: .system)
    let appleButton = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let backgroundTopGlow = GlowView(
        colors: [
            UIColor(red: 0.86, green: 0.92, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.86, green: 0.92, blue: 1.0, alpha: 0.0)
        ]
    )

    private let backgroundBottomGlow = GlowView(
        colors: [
            UIColor(red: 0.95, green: 0.96, blue: 0.99, alpha: 1.0),
            UIColor(red: 0.95, green: 0.96, blue: 0.99, alpha: 0.0)
        ]
    )

    private let logoContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.43, green: 0.35, blue: 0.96, alpha: 1.0)
        view.layer.cornerRadius = 18
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill.badge.checkmark"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome back"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Sign in to continue your journey."
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.49, green: 0.52, blue: 0.58, alpha: 1.0)
        return label
    }()

    private let dividerLineLeft = DividerLineView()
    private let dividerLineRight = DividerLineView()

    private let dividerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "or"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(red: 0.63, green: 0.66, blue: 0.72, alpha: 1.0)
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let fullText = "Don't have an account? Sign up"
        let attributed = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor(red: 0.56, green: 0.59, blue: 0.65, alpha: 1.0)
            ]
        )
        attributed.addAttributes(
            [
                .foregroundColor: UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1.0),
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ],
            range: (fullText as NSString).range(of: "Sign up")
        )
        label.attributedText = attributed
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureFields()
        configureButtons()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundTopGlow.layer.cornerRadius = backgroundTopGlow.bounds.height / 2
        backgroundBottomGlow.layer.cornerRadius = backgroundBottomGlow.bounds.height / 2
    }

    func render(state: LoginViewState) {
        // render 的职责很简单：收到状态后，把 UI 更新到对应样子。
        if emailField.text != state.email {
            emailField.text = state.email
        }

        if passwordField.text != state.password {
            passwordField.text = state.password
        }

        loginButton.isEnabled = state.isLoginButtonEnabled
        loginButton.alpha = state.isLoginButtonEnabled ? 1.0 : 0.75
        loginButton.setTitle(state.isLoading ? "Signing In..." : "Sign In", for: .normal)
    }

    private func configureView() {
        backgroundColor = UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive

        contentView.translatesAutoresizingMaskIntoConstraints = false
        backgroundTopGlow.translatesAutoresizingMaskIntoConstraints = false
        backgroundBottomGlow.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureFields() {
        // 输入框的基础行为都放在视图层配置。
        emailField.placeholder = "Email"
        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        emailField.autocorrectionType = .no
        emailField.autocapitalizationType = .none

        passwordField.placeholder = "Password"
        passwordField.textContentType = .password
        passwordField.isSecureTextEntry = true
        passwordField.returnKeyType = .done
    }

    private func configureButtons() {
        // 按钮的样式也在视图层统一管理，避免控制器里堆 UI 代码。
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("Sign In", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1.0)
        loginButton.layer.cornerRadius = 16
        loginButton.layer.shadowColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 0.28).cgColor
        loginButton.layer.shadowOpacity = 1
        loginButton.layer.shadowRadius = 18
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 10)

        appleButton.translatesAutoresizingMaskIntoConstraints = false
        appleButton.setTitle("  Continue with Apple", for: .normal)
        appleButton.setImage(UIImage(systemName: "applelogo"), for: .normal)
        appleButton.tintColor = .white
        appleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        appleButton.setTitleColor(.white, for: .normal)
        appleButton.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)
        appleButton.layer.cornerRadius = 16

        forgotButton.translatesAutoresizingMaskIntoConstraints = false
        forgotButton.setTitle("Forgot password?", for: .normal)
        forgotButton.setTitleColor(UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1.0), for: .normal)
        forgotButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }

    private func setupLayout() {
        // 这里把页面拆成几个小的 stack，后面你读布局时会更清晰：
        // header / fields / divider / footer
        let headerStack = UIStackView(arrangedSubviews: [logoContainer, titleLabel, subtitleLabel])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 16

        let fieldStack = UIStackView(arrangedSubviews: [emailField, passwordField])
        fieldStack.translatesAutoresizingMaskIntoConstraints = false
        fieldStack.axis = .vertical
        fieldStack.spacing = 12

        let dividerStack = UIStackView(arrangedSubviews: [dividerLineLeft, dividerLabel, dividerLineRight])
        dividerStack.translatesAutoresizingMaskIntoConstraints = false
        dividerStack.axis = .horizontal
        dividerStack.alignment = .center
        dividerStack.spacing = 12

        let contentStack = UIStackView(arrangedSubviews: [
            headerStack,
            fieldStack,
            forgotButton,
            loginButton,
            dividerStack,
            appleButton,
            footerLabel
        ])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 18

        addSubview(backgroundTopGlow)
        addSubview(backgroundBottomGlow)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)
        logoContainer.addSubview(logoImageView)

        NSLayoutConstraint.activate([
            backgroundTopGlow.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 28),
            backgroundTopGlow.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -76),
            backgroundTopGlow.widthAnchor.constraint(equalToConstant: 280),
            backgroundTopGlow.heightAnchor.constraint(equalToConstant: 180),

            backgroundBottomGlow.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -36),
            backgroundBottomGlow.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 94),
            backgroundBottomGlow.widthAnchor.constraint(equalToConstant: 240),
            backgroundBottomGlow.heightAnchor.constraint(equalToConstant: 150),

            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

            contentStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 32),
            contentStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            contentStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 8),

            logoContainer.widthAnchor.constraint(equalToConstant: 68),
            logoContainer.heightAnchor.constraint(equalToConstant: 68),
            logoImageView.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 30),
            logoImageView.heightAnchor.constraint(equalToConstant: 30),

            emailField.heightAnchor.constraint(equalToConstant: 54),
            passwordField.heightAnchor.constraint(equalToConstant: 54),
            loginButton.heightAnchor.constraint(equalToConstant: 54),
            appleButton.heightAnchor.constraint(equalToConstant: 54),
            dividerLineLeft.heightAnchor.constraint(equalToConstant: 1),
            dividerLineRight.heightAnchor.constraint(equalToConstant: 1)
        ])

        dividerLineLeft.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dividerLineRight.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dividerLineLeft.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dividerLineRight.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentStack.setCustomSpacing(28, after: headerStack)
        contentStack.setCustomSpacing(10, after: fieldStack)
        contentStack.setCustomSpacing(22, after: forgotButton)
        contentStack.setCustomSpacing(22, after: loginButton)
        contentStack.setCustomSpacing(22, after: dividerStack)
        contentStack.setCustomSpacing(24, after: appleButton)
    }
}

// 给输入框加左右内边距，并统一聚焦时的视觉效果。
final class InsetTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
        textColor = UIColor(red: 0.13, green: 0.14, blue: 0.19, alpha: 1.0)
        tintColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1.0)
        font = .systemFont(ofSize: 16, weight: .medium)
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.89, green: 0.91, blue: 0.96, alpha: 1.0).cgColor
        attributedPlaceholder = NSAttributedString(
            string: "",
            attributes: [
                .foregroundColor: UIColor(red: 0.69, green: 0.71, blue: 0.76, alpha: 1.0)
            ]
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        // 聚焦时高亮边框，给用户一个“正在输入”的反馈。
        layer.borderColor = UIColor(red: 0.76, green: 0.84, blue: 1.0, alpha: 1.0).cgColor
        layer.shadowColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 0.12).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        // 失焦时恢复默认样式。
        layer.borderColor = UIColor(red: 0.89, green: 0.91, blue: 0.96, alpha: 1.0).cgColor
        layer.shadowOpacity = 0
        return super.resignFirstResponder()
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 18, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 18, dy: 0)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 18, dy: 0)
    }
}

// 背景发光块，只做装饰用途。
private final class GlowView: UIView {
    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        alpha = 0.92
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0.2, y: 0.2)
        gradientLayer.endPoint = CGPoint(x: 0.8, y: 0.8)
        layer.addSublayer(gradientLayer)
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// 中间分割线视图。
private final class DividerLineView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0.89, green: 0.91, blue: 0.95, alpha: 1.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }
}
