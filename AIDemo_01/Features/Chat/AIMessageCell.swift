import UIKit
import SnapKit

// AI 消息 Cell：左侧头像 + 深色半透明毛玻璃卡片。
final class AIMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "AIMessageCell"

    private let avatarView = ChatAIAvatarView()
    private let bubbleView = ChatGlassBubbleView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timeLabel.text = nil
    }

    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        timeLabel.text = message.time
    }

    private func configureView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 18, weight: .regular)
        messageLabel.textColor = UIColor.white.withAlphaComponent(0.94)
        messageLabel.lineBreakMode = .byWordWrapping

        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.42)
    }

    private func setupLayout() {
        contentView.addSubview(avatarView)
        contentView.addSubview(bubbleView)
        contentView.addSubview(timeLabel)
        bubbleView.contentLayoutView.addSubview(messageLabel)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(42)
        }

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(54)
            make.width.lessThanOrEqualTo(contentView.snp.width).multipliedBy(0.74)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18))
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(bubbleView).offset(2)
            make.top.equalTo(bubbleView.snp.bottom).offset(6)
            make.bottom.equalToSuperview().inset(6)
        }
    }
}

// AI 头像：用渐变圆环和 SF Symbol 模拟科幻徽章。
final class ChatAIAvatarView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let ringLayer = CAShapeLayer()
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
        gradientLayer.frame = bounds
        ringLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: 2, dy: 2)).cgPath
    }

    private func configureView() {
        clipsToBounds = true
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.28, green: 0.78, blue: 1.0, alpha: 0.90).cgColor

        gradientLayer.colors = [
            UIColor(red: 0.08, green: 0.65, blue: 1.0, alpha: 0.95).cgColor,
            UIColor(red: 0.03, green: 0.10, blue: 0.32, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.15, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.85, y: 1.0)
        layer.insertSublayer(gradientLayer, at: 0)

        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.62).cgColor
        ringLayer.lineWidth = 1
        layer.addSublayer(ringLayer)

        iconImageView.image = UIImage(
            systemName: "hexagon.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        )
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor(red: 0.82, green: 0.95, blue: 1.0, alpha: 1.0)
    }

    private func setupLayout() {
        addSubview(iconImageView)

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
    }
}

// 公共毛玻璃气泡，AI 文本和输入中状态都会复用。
final class ChatGlassBubbleView: UIView {
    let contentLayoutView = UIView()

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let tintView = UIView()

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
        layer.cornerRadius = 20
        blurView.layer.cornerRadius = 20
        tintView.layer.cornerRadius = 20
    }

    private func configureView() {
        backgroundColor = .clear
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        layer.shadowColor = UIColor(red: 0.00, green: 0.08, blue: 0.18, alpha: 0.55).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)

        blurView.clipsToBounds = true
        tintView.clipsToBounds = true
        tintView.backgroundColor = UIColor(red: 0.09, green: 0.15, blue: 0.27, alpha: 0.62)
        contentLayoutView.backgroundColor = .clear
    }

    private func setupLayout() {
        addSubview(blurView)
        addSubview(tintView)
        addSubview(contentLayoutView)

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tintView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentLayoutView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
