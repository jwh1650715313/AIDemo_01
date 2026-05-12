import UIKit
import SnapKit

// 用户消息 Cell：右侧蓝色渐变气泡，底部带时间和已读状态。
final class UserMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "UserMessageCell"

    private let bubbleView = UserGradientBubbleView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let readLabel = UILabel()
    private let metaStack = UIStackView()

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
        readLabel.isHidden = !message.isRead
    }

    private func configureView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        messageLabel.textColor = .white
        messageLabel.lineBreakMode = .byWordWrapping

        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.42)

        readLabel.text = "✓✓"
        readLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        readLabel.textColor = UIColor(red: 0.22, green: 0.76, blue: 1.0, alpha: 1.0)

        metaStack.axis = .horizontal
        metaStack.alignment = .center
        metaStack.spacing = 4
    }

    private func setupLayout() {
        contentView.addSubview(bubbleView)
        contentView.addSubview(metaStack)
        bubbleView.addSubview(messageLabel)

        [timeLabel, readLabel].forEach(metaStack.addArrangedSubview)

        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().inset(20)
            make.leading.greaterThanOrEqualToSuperview().offset(72)
            make.width.lessThanOrEqualTo(contentView.snp.width).multipliedBy(0.72)
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 15, left: 18, bottom: 15, right: 18))
        }

        metaStack.snp.makeConstraints { make in
            make.top.equalTo(bubbleView.snp.bottom).offset(6)
            make.trailing.equalTo(bubbleView).inset(4)
            make.bottom.equalToSuperview().inset(8)
        }
    }
}

// 渐变气泡单独封装，避免 Cell 里混入太多图层细节。
private final class UserGradientBubbleView: UIView {
    private let gradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 22
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 22
    }

    private func configureView() {
        clipsToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)

        gradientLayer.colors = [
            UIColor(red: 0.04, green: 0.42, blue: 0.98, alpha: 1.0).cgColor,
            UIColor(red: 0.14, green: 0.64, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.23, blue: 0.94, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
    }
}
