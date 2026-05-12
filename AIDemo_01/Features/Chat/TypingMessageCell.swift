import UIKit
import SnapKit

// AI 正在输入 Cell：左侧头像 + 三个跳动光点。
final class TypingMessageCell: UICollectionViewCell {
    static let reuseIdentifier = "TypingMessageCell"

    private let avatarView = ChatAIAvatarView()
    private let bubbleView = ChatGlassBubbleView()
    private let dotStack = UIStackView()
    private let dotViews: [UIView] = [UIView(), UIView(), UIView()]

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? stopAnimatingDots() : startAnimatingDots()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startAnimatingDots()
    }

    func configure(with message: ChatMessage) {
        // 输入中状态暂时不展示时间，保留参数方便后续扩展真实流式回复。
        _ = message
    }

    private func configureView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        dotStack.axis = .horizontal
        dotStack.alignment = .center
        dotStack.spacing = 8

        dotViews.enumerated().forEach { index, dotView in
            dotView.backgroundColor = index == 0
                ? UIColor(red: 0.18, green: 0.56, blue: 1.0, alpha: 1.0)
                : UIColor.white.withAlphaComponent(0.35)
            dotView.layer.cornerRadius = 5
        }
    }

    private func setupLayout() {
        contentView.addSubview(avatarView)
        contentView.addSubview(bubbleView)
        bubbleView.contentLayoutView.addSubview(dotStack)
        dotViews.forEach(dotStack.addArrangedSubview)

        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(42)
        }

        bubbleView.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(96)
            make.height.equalTo(52)
            make.bottom.equalToSuperview().inset(10)
        }

        dotStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        dotViews.forEach { dotView in
            dotView.snp.makeConstraints { make in
                make.size.equalTo(10)
            }
        }
    }

    private func startAnimatingDots() {
        dotViews.enumerated().forEach { index, dotView in
            dotView.layer.removeAnimation(forKey: "typing.opacity")

            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0.28
            animation.toValue = 1.0
            animation.duration = 0.7
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.18
            dotView.layer.add(animation, forKey: "typing.opacity")
        }
    }

    private func stopAnimatingDots() {
        dotViews.forEach { dotView in
            dotView.layer.removeAnimation(forKey: "typing.opacity")
        }
    }
}
