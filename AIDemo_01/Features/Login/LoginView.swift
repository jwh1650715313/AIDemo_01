import UIKit
import SnapKit

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
        view.backgroundColor = UIColor(red: 0.43, green: 0.35, blue: 0.96, alpha: 1.0)
        view.layer.cornerRadius = 18
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill.badge.checkmark"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "欢迎回来"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "登录后继续你的智能旅程"
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textAlignment = .center
        label.textColor = UIColor(red: 0.49, green: 0.52, blue: 0.58, alpha: 1.0)
        return label
    }()

    private let dividerLineLeft = DividerLineView()
    private let dividerLineRight = DividerLineView()

    private let dividerLabel: UILabel = {
        let label = UILabel()
        label.text = "或"
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(red: 0.63, green: 0.66, blue: 0.72, alpha: 1.0)
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel()
        let fullText = "还没有账号？立即注册"
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
            range: (fullText as NSString).range(of: "立即注册")
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
        loginButton.setTitle(state.isLoading ? "登录中..." : "登录", for: .normal)
    }

    private func configureView() {
        backgroundColor = UIColor(red: 0.98, green: 0.99, blue: 1.0, alpha: 1.0)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
    }

    private func configureFields() {
        // 输入框的基础行为都放在视图层配置。
        emailField.placeholder = "手机号"
        emailField.keyboardType = .numberPad
        emailField.textContentType = .telephoneNumber
        emailField.autocorrectionType = .no
        emailField.autocapitalizationType = .none

        passwordField.placeholder = "密码"
        passwordField.textContentType = .password
        passwordField.isSecureTextEntry = true
        passwordField.returnKeyType = .done
    }

    private func configureButtons() {
        // 按钮的样式也在视图层统一管理，避免控制器里堆 UI 代码。
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1.0)
        loginButton.layer.cornerRadius = 16
        loginButton.layer.shadowColor = UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 0.28).cgColor
        loginButton.layer.shadowOpacity = 1
        loginButton.layer.shadowRadius = 18
        loginButton.layer.shadowOffset = CGSize(width: 0, height: 10)

        appleButton.setTitle("  微信登录", for: .normal)
        appleButton.setImage(UIImage(systemName: "message.fill"), for: .normal)
        appleButton.tintColor = .white
        appleButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        appleButton.setTitleColor(.white, for: .normal)
        appleButton.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)
        appleButton.layer.cornerRadius = 16

        forgotButton.setTitle("忘记密码？", for: .normal)
        forgotButton.setTitleColor(UIColor(red: 0.19, green: 0.47, blue: 0.98, alpha: 1.0), for: .normal)
        forgotButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    }

    private func setupLayout() {
        // 这里把页面拆成几个小的 stack，后面你读布局时会更清晰：
        // header / fields / divider / footer
        let headerStack = UIStackView(arrangedSubviews: [logoContainer, titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.alignment = .center
        headerStack.spacing = 16

        let fieldStack = UIStackView(arrangedSubviews: [emailField, passwordField])
        fieldStack.axis = .vertical
        fieldStack.spacing = 12

        let dividerStack = UIStackView(arrangedSubviews: [dividerLineLeft, dividerLabel, dividerLineRight])
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
        contentStack.axis = .vertical
        contentStack.spacing = 18

        addSubview(backgroundTopGlow)
        addSubview(backgroundBottomGlow)
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStack)
        logoContainer.addSubview(logoImageView)

        backgroundTopGlow.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(28)
            make.centerX.equalToSuperview().offset(-76)
            make.width.equalTo(280)
            make.height.equalTo(180)
        }

        backgroundBottomGlow.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-36)
            make.centerX.equalToSuperview().offset(94)
            make.width.equalTo(240)
            make.height.equalTo(150)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
            make.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
        }

        contentStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.centerY.equalToSuperview().offset(8)
        }

        logoContainer.snp.makeConstraints { make in
            make.size.equalTo(68)
        }

        logoImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(30)
        }

        emailField.snp.makeConstraints { make in
            make.height.equalTo(54)
        }

        passwordField.snp.makeConstraints { make in
            make.height.equalTo(54)
        }

        loginButton.snp.makeConstraints { make in
            make.height.equalTo(54)
        }

        appleButton.snp.makeConstraints { make in
            make.height.equalTo(54)
        }

        dividerLineLeft.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

        dividerLineRight.snp.makeConstraints { make in
            make.height.equalTo(1)
        }

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
        backgroundColor = UIColor(red: 0.89, green: 0.91, blue: 0.95, alpha: 1.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }
}
