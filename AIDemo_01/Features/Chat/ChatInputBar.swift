import UIKit
import SnapKit

// 底部悬浮输入栏：只负责输入和按钮事件，不关心消息发送后的业务逻辑。
final class ChatInputBar: UIView {
    var onSend: ((String) -> Void)?

    let addButton = UIButton(type: .system)
    let textField = UITextField()
    let voiceButton = UIButton(type: .system)
    let sendButton = UIButton(type: .system)

    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let contentStack = UIStackView()
    private let sendGradientLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        configureButtons()
        configureTextField()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentStack.layoutIfNeeded()
        layer.cornerRadius = bounds.height / 2
        backgroundBlurView.layer.cornerRadius = bounds.height / 2
        addButton.layer.cornerRadius = addButton.bounds.height / 2
        sendButton.layer.cornerRadius = sendButton.bounds.height / 2
        sendGradientLayer.frame = sendButton.bounds
        sendGradientLayer.cornerRadius = sendButton.bounds.height / 2
        if let imageView = sendButton.imageView {
            sendButton.bringSubviewToFront(imageView)
        }
    }

    private func configureView() {
        backgroundColor = UIColor(red: 0.06, green: 0.14, blue: 0.28, alpha: 0.48)
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 0.16, green: 0.58, blue: 1.0, alpha: 0.85).cgColor
        layer.shadowColor = UIColor(red: 0.02, green: 0.45, blue: 1.0, alpha: 0.42).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 6)
        clipsToBounds = false

        backgroundBlurView.isUserInteractionEnabled = false
        backgroundBlurView.clipsToBounds = true

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 12
    }

    private func configureButtons() {
        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        addButton.clipsToBounds = true
        addButton.layer.borderWidth = 1
        addButton.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        voiceButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        voiceButton.tintColor = .white

        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .white
        sendButton.clipsToBounds = true
        sendButton.layer.insertSublayer(sendGradientLayer, at: 0)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        sendGradientLayer.colors = [
            UIColor(red: 0.12, green: 0.66, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.30, green: 0.36, blue: 1.0, alpha: 1.0).cgColor
        ]
        sendGradientLayer.startPoint = CGPoint(x: 0.12, y: 0.0)
        sendGradientLayer.endPoint = CGPoint(x: 0.92, y: 1.0)
    }

    private func configureTextField() {
        textField.delegate = self
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.tintColor = UIColor(red: 0.25, green: 0.70, blue: 1.0, alpha: 1.0)
        textField.font = .systemFont(ofSize: 17, weight: .medium)
        textField.returnKeyType = .send
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.attributedPlaceholder = NSAttributedString(
            string: "输入你的问题...",
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.42),
                .font: UIFont.systemFont(ofSize: 17, weight: .medium)
            ]
        )
    }

    private func setupLayout() {
        addSubview(backgroundBlurView)
        addSubview(contentStack)

        [addButton, textField, voiceButton, sendButton].forEach(contentStack.addArrangedSubview)

        backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 10))
        }

        addButton.snp.makeConstraints { make in
            make.size.equalTo(48)
        }

        voiceButton.snp.makeConstraints { make in
            make.size.equalTo(42)
        }

        sendButton.snp.makeConstraints { make in
            make.size.equalTo(52)
        }

        textField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    @objc private func sendButtonTapped() {
        sendCurrentText()
    }

    func setSending(_ isSending: Bool) {
        sendButton.isEnabled = !isSending
        sendButton.alpha = isSending ? 0.55 : 1.0
    }

    private func sendCurrentText() {
        guard sendButton.isEnabled else { return }

        let text = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        textField.text = nil
        onSend?(text)
    }
}

extension ChatInputBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendCurrentText()
        return true
    }
}
