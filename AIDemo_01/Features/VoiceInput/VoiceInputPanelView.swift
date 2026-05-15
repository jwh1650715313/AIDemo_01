import SnapKit
import UIKit

// 底部语音输入面板：只负责展示识别状态和把用户操作通过 closure 抛给外部。
final class VoiceInputPanelView: UIView {
    var onTextChanged: ((String) -> Void)?
    var onTextConfirmed: ((String) -> Void)?
    var onSend: ((String) -> Void)?
    var onCancel: (() -> Void)?
    var onDismiss: (() -> Void)?

    private let voiceManager: VoiceInputManager
    private let contentView = UIView()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let panelGradientLayer = CAGradientLayer()
    private let panelGradientMaskLayer = CAShapeLayer()
    private let panelBorderLayer = CAShapeLayer()
    private let handleView = UIView()
    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let waveformView = VoiceWaveformView()
    private let micHaloView = MicListeningHaloView()
    private let micButton = UIButton(type: .system)
    private let micGradientLayer = CAGradientLayer()
    private let micHighlightLayer = CAGradientLayer()
    private let micIconView = UIImageView()
    private let transcriptContainerView = UIView()
    private let transcriptTextView = UITextView()
    private let moreLabel = UILabel()
    private let levelIndicatorView = VoiceLevelIndicatorView()
    private let cancelButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let sendGradientLayer = CAGradientLayer()
    private let sendHighlightLayer = CAGradientLayer()
    private let sendIconView = UIImageView()
    private let cancelLabel = UILabel()
    private let sendLabel = UILabel()
    private let settingsButton = UIButton(type: .system)

    private var recognizedText = ""
    private var hasStartedRecognition = false

    init(voiceManager: VoiceInputManager? = nil) {
        // VoiceInputManager 是 MainActor 隔离对象，避免在默认参数表达式里直接创建。
        self.voiceManager = voiceManager ?? VoiceInputManager()
        super.init(frame: .zero)
        configureView()
        configureContentView()
        configureLabels()
        configureButtons()
        configureTranscript()
        setupLayout()
        bindVoiceManager()
        updateSendButton(isEnabled: false)
        applyState(.idle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        waveformView.setAnimating(false)
        levelIndicatorView.setAnimating(false)
        micHaloView.setAnimating(false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layoutIfNeeded()
        panelGradientLayer.frame = contentView.bounds
        panelGradientMaskLayer.frame = contentView.bounds
        panelBorderLayer.frame = contentView.bounds
        let panelPath = UIBezierPath(
            roundedRect: contentView.bounds.insetBy(dx: 0.5, dy: 0.5),
            cornerRadius: 36
        ).cgPath
        let gradientMaskPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: 36
        ).cgPath
        panelGradientMaskLayer.path = gradientMaskPath
        panelBorderLayer.path = panelPath
        contentView.layer.shadowPath = gradientMaskPath

        micGradientLayer.frame = micButton.bounds
        micGradientLayer.cornerRadius = micButton.bounds.height / 2
        micHighlightLayer.frame = micButton.bounds
        micHighlightLayer.cornerRadius = micButton.bounds.height / 2
        sendGradientLayer.frame = sendButton.bounds
        sendGradientLayer.cornerRadius = sendButton.bounds.height / 2
        sendHighlightLayer.frame = sendButton.bounds
        sendHighlightLayer.cornerRadius = sendButton.bounds.height / 2

        [contentView, blurView].forEach { view in
            view.layer.cornerRadius = 36
            view.layer.cornerCurve = .continuous
        }
        transcriptContainerView.layer.cornerRadius = 31
        micButton.layer.cornerRadius = micButton.bounds.height / 2
        cancelButton.layer.cornerRadius = cancelButton.bounds.height / 2
        sendButton.layer.cornerRadius = sendButton.bounds.height / 2
        micButton.bringSubviewToFront(micIconView)
        sendButton.bringSubviewToFront(sendIconView)
    }

    // 以外挂视图形式弹出，不改变原页面层级和导航结构。
    func present(in parentView: UIView) {
        guard superview == nil else { return }

        parentView.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        parentView.layoutIfNeeded()
        alpha = 0
        contentView.transform = CGAffineTransform(translationX: 0, y: parentView.bounds.height)

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.92,
            initialSpringVelocity: 0.18,
            options: [.curveEaseOut, .beginFromCurrentState]
        ) {
            self.alpha = 1
            self.contentView.transform = .identity
        } completion: { [weak self] _ in
            self?.startRecognitionIfNeeded()
        }
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        let animations = {
            self.alpha = 0
            self.contentView.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
        }

        let finish: (Bool) -> Void = { [weak self] _ in
            self?.waveformView.setAnimating(false)
            self?.levelIndicatorView.setAnimating(false)
            self?.micHaloView.setAnimating(false)
            self?.removeFromSuperview()
            self?.onDismiss?()
            completion?()
        }

        guard animated else {
            animations()
            finish(true)
            return
        }

        UIView.animate(
            withDuration: 0.24,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: animations,
            completion: finish
        )
    }

    private func configureView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.10)
        isAccessibilityElement = false
    }

    private func configureContentView() {
        contentView.backgroundColor = UIColor(red: 0.02, green: 0.09, blue: 0.21, alpha: 0.72)
        contentView.layer.shadowColor = UIColor(red: 0.0, green: 0.42, blue: 1.0, alpha: 0.40).cgColor
        contentView.layer.shadowOpacity = 1
        contentView.layer.shadowRadius = 28
        contentView.layer.shadowOffset = CGSize(width: 0, height: -6)
        contentView.clipsToBounds = false

        panelGradientLayer.colors = [
            UIColor(red: 0.02, green: 0.10, blue: 0.24, alpha: 0.96).cgColor,
            UIColor(red: 0.01, green: 0.05, blue: 0.14, alpha: 0.96).cgColor
        ]
        panelGradientLayer.startPoint = CGPoint(x: 0.12, y: 0.0)
        panelGradientLayer.endPoint = CGPoint(x: 0.88, y: 1.0)
        panelGradientLayer.mask = panelGradientMaskLayer
        contentView.layer.insertSublayer(panelGradientLayer, at: 0)

        panelBorderLayer.fillColor = UIColor.clear.cgColor
        panelBorderLayer.strokeColor = UIColor(red: 0.11, green: 0.55, blue: 1.0, alpha: 0.88).cgColor
        panelBorderLayer.lineWidth = 1
        contentView.layer.addSublayer(panelBorderLayer)

        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false

        handleView.backgroundColor = UIColor.white.withAlphaComponent(0.64)
        handleView.layer.cornerRadius = 3
    }

    private func configureLabels() {
        titleLabel.text = "正在聆听..."
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.86

        hintLabel.text = "说出你的问题，我来帮你解答"
        hintLabel.textAlignment = .center
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.48)
        hintLabel.font = .systemFont(ofSize: 15, weight: .regular)
        hintLabel.numberOfLines = 2

        activityIndicator.color = UIColor(red: 0.35, green: 0.82, blue: 1.0, alpha: 1.0)
        activityIndicator.hidesWhenStopped = true

        cancelLabel.text = "取消"
        cancelLabel.textAlignment = .center
        cancelLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        cancelLabel.font = .systemFont(ofSize: 15, weight: .medium)

        sendLabel.text = "发送"
        sendLabel.textAlignment = .center
        sendLabel.textColor = .white
        sendLabel.font = .systemFont(ofSize: 15, weight: .medium)
    }

    private func configureButtons() {
        micButton.setImage(nil, for: .normal)
        micButton.tintColor = .white
        micButton.isUserInteractionEnabled = false
        micButton.layer.borderWidth = 7
        micButton.layer.borderColor = UIColor(red: 0.68, green: 0.92, blue: 1.0, alpha: 0.72).cgColor
        micButton.layer.shadowColor = UIColor(red: 0.15, green: 0.70, blue: 1.0, alpha: 0.80).cgColor
        micButton.layer.shadowOpacity = 1
        micButton.layer.shadowRadius = 34
        micButton.layer.shadowOffset = .zero

        micGradientLayer.colors = [
            UIColor(red: 0.42, green: 0.90, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.58, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.14, green: 0.26, blue: 1.0, alpha: 1.0).cgColor
        ]
        micGradientLayer.locations = [0.0, 0.52, 1.0]
        micGradientLayer.startPoint = CGPoint(x: 0.18, y: 0.08)
        micGradientLayer.endPoint = CGPoint(x: 0.88, y: 0.95)
        micButton.layer.insertSublayer(micGradientLayer, at: 0)

        micHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.38).cgColor,
            UIColor.white.withAlphaComponent(0.06).cgColor,
            UIColor.clear.cgColor
        ]
        micHighlightLayer.locations = [0.0, 0.38, 1.0]
        micHighlightLayer.startPoint = CGPoint(x: 0.18, y: 0.05)
        micHighlightLayer.endPoint = CGPoint(x: 0.82, y: 0.88)
        micButton.layer.insertSublayer(micHighlightLayer, above: micGradientLayer)

        configureSymbolIcon(micIconView, systemName: "mic.fill", pointSize: 40, weight: .medium)
        micButton.addSubview(micIconView)
        micIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(48)
        }

        configureCircleButton(
            cancelButton,
            systemName: "xmark",
            backgroundColor: UIColor(red: 0.02, green: 0.08, blue: 0.18, alpha: 0.84)
        )
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(red: 0.22, green: 0.67, blue: 1.0, alpha: 0.82).cgColor
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        configureCircleButton(sendButton, systemName: "paperplane.fill", backgroundColor: .clear)
        sendButton.setImage(nil, for: .normal)
        sendButton.clipsToBounds = false
        sendButton.layer.shadowColor = UIColor(red: 0.20, green: 0.55, blue: 1.0, alpha: 0.88).cgColor
        sendButton.layer.shadowOpacity = 1
        sendButton.layer.shadowRadius = 24
        sendButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        sendGradientLayer.colors = [
            UIColor(red: 0.20, green: 0.78, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.16, green: 0.45, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.34, green: 0.24, blue: 1.0, alpha: 1.0).cgColor
        ]
        sendGradientLayer.locations = [0.0, 0.50, 1.0]
        sendGradientLayer.startPoint = CGPoint(x: 0.14, y: 0.06)
        sendGradientLayer.endPoint = CGPoint(x: 0.88, y: 0.96)
        sendButton.layer.insertSublayer(sendGradientLayer, at: 0)

        sendHighlightLayer.colors = [
            UIColor.white.withAlphaComponent(0.30).cgColor,
            UIColor.white.withAlphaComponent(0.03).cgColor,
            UIColor.clear.cgColor
        ]
        sendHighlightLayer.locations = [0.0, 0.45, 1.0]
        sendHighlightLayer.startPoint = CGPoint(x: 0.18, y: 0.0)
        sendHighlightLayer.endPoint = CGPoint(x: 0.86, y: 0.86)
        sendButton.layer.insertSublayer(sendHighlightLayer, above: sendGradientLayer)

        configureSymbolIcon(sendIconView, systemName: "paperplane.fill", pointSize: 34, weight: .semibold)
        sendButton.addSubview(sendIconView)
        sendIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)

        settingsButton.setTitle("去设置", for: .normal)
        settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        settingsButton.tintColor = UIColor(red: 0.44, green: 0.84, blue: 1.0, alpha: 1.0)
        settingsButton.setTitleColor(UIColor(red: 0.44, green: 0.84, blue: 1.0, alpha: 1.0), for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        settingsButton.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        settingsButton.layer.cornerRadius = 18
        settingsButton.layer.borderWidth = 1
        settingsButton.layer.borderColor = UIColor(red: 0.23, green: 0.68, blue: 1.0, alpha: 0.42).cgColor
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        settingsButton.isHidden = true
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
    }

    private func configureCircleButton(_ button: UIButton, systemName: String, backgroundColor: UIColor) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = backgroundColor
        button.clipsToBounds = true
    }

    private func configureSymbolIcon(
        _ imageView: UIImageView,
        systemName: String,
        pointSize: CGFloat,
        weight: UIImage.SymbolWeight
    ) {
        let configuration = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        imageView.image = UIImage(systemName: systemName, withConfiguration: configuration)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
    }

    private func configureTranscript() {
        transcriptContainerView.backgroundColor = UIColor(red: 0.08, green: 0.18, blue: 0.34, alpha: 0.72)
        transcriptContainerView.layer.borderWidth = 1
        transcriptContainerView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        transcriptTextView.text = "“帮我查询今天深圳的天气”"
        transcriptTextView.textColor = UIColor.white.withAlphaComponent(0.56)
        transcriptTextView.font = .systemFont(ofSize: 19, weight: .medium)
        transcriptTextView.backgroundColor = .clear
        transcriptTextView.textContainerInset = UIEdgeInsets(top: 17, left: 18, bottom: 12, right: 52)
        transcriptTextView.textContainer.lineFragmentPadding = 0
        transcriptTextView.isEditable = false
        transcriptTextView.isScrollEnabled = true
        transcriptTextView.showsVerticalScrollIndicator = false

        moreLabel.text = "..."
        moreLabel.textAlignment = .center
        moreLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        moreLabel.font = .systemFont(ofSize: 24, weight: .semibold)
    }

    private func setupLayout() {
        addSubview(contentView)

        contentView.addSubview(blurView)
        contentView.addSubview(handleView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(hintLabel)
        contentView.addSubview(activityIndicator)
        contentView.addSubview(waveformView)
        contentView.addSubview(micHaloView)
        contentView.addSubview(micButton)
        contentView.addSubview(transcriptContainerView)
        contentView.addSubview(levelIndicatorView)
        contentView.addSubview(settingsButton)

        transcriptContainerView.addSubview(transcriptTextView)
        transcriptContainerView.addSubview(moreLabel)

        let cancelStack = makeActionStack(button: cancelButton, label: cancelLabel)
        let sendStack = makeActionStack(button: sendButton, label: sendLabel)
        contentView.addSubview(cancelStack)
        contentView.addSubview(sendStack)

        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom).offset(-8)
            make.top.greaterThanOrEqualTo(safeAreaLayoutGuide.snp.top).offset(24)
            make.height.equalToSuperview().multipliedBy(0.68).priority(.high)
            make.height.greaterThanOrEqualTo(530).priority(.high)
            make.height.lessThanOrEqualTo(640)
        }

        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        handleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.centerX.equalToSuperview()
            make.width.equalTo(78)
            make.height.equalTo(6)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(handleView.snp.bottom).offset(34)
            make.leading.trailing.equalToSuperview().inset(28)
        }

        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(28)
        }

        activityIndicator.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.centerX.equalToSuperview().offset(126)
        }

        waveformView.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(26)
            make.leading.trailing.equalToSuperview().inset(2)
            make.height.equalTo(132).priority(.medium)
            make.height.greaterThanOrEqualTo(96)
        }

        micHaloView.snp.makeConstraints { make in
            make.center.equalTo(waveformView)
            make.size.equalTo(164)
        }

        micButton.snp.makeConstraints { make in
            make.center.equalTo(micHaloView)
            make.size.equalTo(90)
        }

        transcriptContainerView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(waveformView.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(48)
            make.bottom.equalTo(levelIndicatorView.snp.top).offset(-18)
            make.height.equalTo(62)
        }

        transcriptTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        moreLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalToSuperview().offset(-2)
            make.width.equalTo(34)
        }

        levelIndicatorView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(cancelStack.snp.top).offset(-18)
            make.width.equalTo(132)
            make.height.equalTo(28)
        }

        settingsButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(levelIndicatorView)
            make.height.equalTo(36)
        }

        cancelStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(62)
            make.bottom.equalToSuperview().inset(32)
            make.width.equalTo(82)
        }

        sendStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(62)
            make.bottom.equalTo(cancelStack)
            make.width.equalTo(82)
        }
    }

    private func makeActionStack(button: UIButton, label: UILabel) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [button, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 9

        button.snp.makeConstraints { make in
            make.size.equalTo(72)
        }

        return stack
    }

    private func bindVoiceManager() {
        voiceManager.onStateChange = { [weak self] state in
            self?.applyState(state)
        }

        voiceManager.onRecognizedText = { [weak self] text in
            self?.updateRecognizedText(text)
        }

        voiceManager.onFinalText = { [weak self] text in
            self?.updateRecognizedText(text)
        }

        voiceManager.onAudioEnergyChange = { [weak self] levels in
            self?.waveformView.update(levels: levels)
            self?.levelIndicatorView.update(levels: levels)
        }

        voiceManager.onError = { [weak self] error in
            self?.applyError(error)
        }
    }

    private func startRecognitionIfNeeded() {
        guard !hasStartedRecognition else { return }
        hasStartedRecognition = true
        waveformView.setAnimating(true)
        levelIndicatorView.setAnimating(true)
        startMicPulse()
        voiceManager.startListening()
    }

    private func updateRecognizedText(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        recognizedText = trimmedText
        onTextChanged?(trimmedText)

        if trimmedText.isEmpty {
            transcriptTextView.text = "“帮我查询今天深圳的天气”"
            transcriptTextView.textColor = UIColor.white.withAlphaComponent(0.56)
        } else {
            transcriptTextView.text = trimmedText
            transcriptTextView.textColor = .white
        }

        updateSendButton(isEnabled: !trimmedText.isEmpty && voiceManager.state != .requestingPermission)
    }

    private func applyState(_ state: VoiceInputManager.State) {
        switch state {
        case .idle:
            titleLabel.text = "正在聆听..."
            hintLabel.text = "说出你的问题，我来帮你解答"
            settingsButton.isHidden = true
            levelIndicatorView.isHidden = false
            activityIndicator.stopAnimating()
            waveformView.setAnimating(false)
            levelIndicatorView.setAnimating(false)
            micHaloView.setAnimating(false)
        case .requestingPermission:
            titleLabel.text = "正在准备语音识别"
            hintLabel.text = "请确认麦克风和语音识别权限"
            settingsButton.isHidden = true
            levelIndicatorView.isHidden = false
            activityIndicator.startAnimating()
            micHaloView.setAnimating(false)
            updateSendButton(isEnabled: false)
        case .ready, .listening:
            titleLabel.text = "正在聆听..."
            hintLabel.text = "说出你的问题，我来帮你解答"
            settingsButton.isHidden = true
            levelIndicatorView.isHidden = false
            activityIndicator.stopAnimating()
            waveformView.setAnimating(true)
            levelIndicatorView.setAnimating(true)
            startMicPulse()
            updateSendButton(isEnabled: !recognizedText.isEmpty)
        case .stopping:
            titleLabel.text = "正在整理语音"
            hintLabel.text = "请稍等"
            activityIndicator.startAnimating()
            micHaloView.setAnimating(false)
            updateSendButton(isEnabled: false)
        case .cancelled:
            activityIndicator.stopAnimating()
            waveformView.setAnimating(false)
            levelIndicatorView.setAnimating(false)
            micHaloView.setAnimating(false)
        case .failed:
            activityIndicator.stopAnimating()
            waveformView.setAnimating(false)
            levelIndicatorView.setAnimating(false)
            micHaloView.setAnimating(false)
            updateSendButton(isEnabled: false)
        }
    }

    private func applyError(_ error: VoiceInputManager.VoiceInputError) {
        switch error {
        case .speechRecognitionUnavailable, .unsupportedLocale:
            titleLabel.text = "语音识别不可用"
        default:
            titleLabel.text = "识别失败"
        }

        hintLabel.text = error.localizedDescription
        if case .microphonePermissionDenied = error {
            settingsButton.isHidden = false
            levelIndicatorView.isHidden = true
        } else if case .speechPermissionDenied = error {
            settingsButton.isHidden = false
            levelIndicatorView.isHidden = true
        } else {
            settingsButton.isHidden = true
            levelIndicatorView.isHidden = false
        }
        micHaloView.setAnimating(false)
        updateSendButton(isEnabled: false)
    }

    private func updateSendButton(isEnabled: Bool) {
        sendButton.isEnabled = isEnabled
        sendButton.alpha = isEnabled ? 1.0 : 0.38
        sendLabel.alpha = isEnabled ? 1.0 : 0.48
        sendGradientLayer.opacity = isEnabled ? 1.0 : 0.45
        sendHighlightLayer.opacity = isEnabled ? 1.0 : 0.42
        sendIconView.alpha = isEnabled ? 1.0 : 0.72
    }

    private func startMicPulse() {
        micHaloView.setAnimating(true)
    }

    @objc private func cancelButtonTapped() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.voiceManager.cancelListening()
            self.onCancel?()
            self.dismiss()
        }
    }

    @objc private func sendButtonTapped() {
        let textBeforeStop = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textBeforeStop.isEmpty else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let finalText = await self.voiceManager.stopListening()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let textToSend = finalText.isEmpty ? textBeforeStop : finalText
            guard !textToSend.isEmpty else { return }

            self.onTextConfirmed?(textToSend)
            self.dismiss { [weak self] in
                self?.onSend?(textToSend)
            }
        }
    }

    @objc private func settingsButtonTapped() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// 麦克风外层聆听光环：用原生 layer 画 3 层半透明圆环和柔和径向光。
private final class MicListeningHaloView: UIView {
    private let glowLayer = CAGradientLayer()
    private let ringLayers = [CAShapeLayer(), CAShapeLayer(), CAShapeLayer()]
    private let ringInsets: [CGFloat] = [3, 22, 40]
    private let ringAlphas: [CGFloat] = [0.26, 0.34, 0.48]

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        glowLayer.frame = bounds

        ringLayers.enumerated().forEach { index, ringLayer in
            ringLayer.frame = bounds
            ringLayer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: ringInsets[index], dy: ringInsets[index])).cgPath
        }
    }

    func setAnimating(_ isAnimating: Bool) {
        glowLayer.removeAnimation(forKey: "voice.halo.glow")
        ringLayers.forEach { $0.removeAnimation(forKey: "voice.halo.pulse") }

        guard isAnimating else {
            glowLayer.opacity = 0.82
            ringLayers.enumerated().forEach { index, ringLayer in
                ringLayer.opacity = Float(ringAlphas[index])
            }
            return
        }

        let glowPulse = CABasicAnimation(keyPath: "opacity")
        glowPulse.fromValue = 0.62
        glowPulse.toValue = 1.0
        glowPulse.duration = 1.35
        glowPulse.autoreverses = true
        glowPulse.repeatCount = .infinity
        glowPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowLayer.add(glowPulse, forKey: "voice.halo.glow")

        ringLayers.enumerated().forEach { index, ringLayer in
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 0.96
            scaleAnimation.toValue = 1.06 + CGFloat(index) * 0.035

            let opacityAnimation = CABasicAnimation(keyPath: "opacity")
            opacityAnimation.fromValue = ringAlphas[index]
            opacityAnimation.toValue = ringAlphas[index] * 0.34

            let group = CAAnimationGroup()
            group.animations = [scaleAnimation, opacityAnimation]
            group.duration = 1.45 + Double(index) * 0.18
            group.beginTime = CACurrentMediaTime() + Double(index) * 0.16
            group.autoreverses = true
            group.repeatCount = .infinity
            group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            ringLayer.add(group, forKey: "voice.halo.pulse")
        }
    }

    private func configureLayers() {
        backgroundColor = .clear
        isUserInteractionEnabled = false

        glowLayer.type = .radial
        glowLayer.colors = [
            UIColor(red: 0.12, green: 0.72, blue: 1.0, alpha: 0.35).cgColor,
            UIColor(red: 0.06, green: 0.40, blue: 1.0, alpha: 0.16).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.locations = [0.0, 0.52, 1.0]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        glowLayer.opacity = 0.82
        layer.addSublayer(glowLayer)

        ringLayers.enumerated().forEach { index, ringLayer in
            ringLayer.fillColor = UIColor.clear.cgColor
            ringLayer.strokeColor = UIColor(red: 0.18, green: 0.78, blue: 1.0, alpha: ringAlphas[index]).cgColor
            ringLayer.lineWidth = index == 2 ? 1.8 : 1.2
            ringLayer.shadowColor = UIColor(red: 0.05, green: 0.68, blue: 1.0, alpha: 0.78).cgColor
            ringLayer.shadowOpacity = 1
            ringLayer.shadowRadius = 9 + CGFloat(index) * 3
            ringLayer.shadowOffset = .zero
            ringLayer.opacity = Float(ringAlphas[index])
            layer.addSublayer(ringLayer)
        }
    }
}

// 声波视图：根据 AVAudioEngine 的能量值刷新，同时在无能量输入时保持轻微流动动画。
private final class VoiceWaveformView: UIView {
    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0
    private var level: CGFloat = 0.18

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    func setAnimating(_ isAnimating: Bool) {
        if isAnimating {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        } else {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    func update(levels: [Float]) {
        guard !levels.isEmpty else { return }
        let recentLevels = levels.suffix(18)
        let average = recentLevels.reduce(Float(0), +) / Float(recentLevels.count)
        level = CGFloat(min(max(average, 0.08), 1.0))
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard rect.width > 0, rect.height > 0 else { return }

        drawCenterBeam(in: rect)
        drawWave(in: rect, amplitudeRatio: 0.33 + level * 0.34, alpha: 0.16, lineWidth: 10.0, shadowBlur: 16)
        drawWave(in: rect, amplitudeRatio: 0.33 + level * 0.34, alpha: 0.90, lineWidth: 2.4, shadowBlur: 7)
        drawWave(in: rect, amplitudeRatio: 0.22 + level * 0.24, alpha: 0.46, lineWidth: 1.4, phaseOffset: .pi / 2, shadowBlur: 4)
        drawSparkField(in: rect)
    }

    private func drawWave(
        in rect: CGRect,
        amplitudeRatio: CGFloat,
        alpha: CGFloat,
        lineWidth: CGFloat,
        phaseOffset: CGFloat = 0,
        shadowBlur: CGFloat = 0
    ) {
        let path = UIBezierPath()
        let midY = rect.midY
        let amplitude = rect.height * amplitudeRatio * 0.34
        let frequency: CGFloat = 0.044
        let samples = Int(rect.width)

        for xIndex in 0...samples {
            let x = CGFloat(xIndex)
            let normalizedDistance = abs(x - rect.midX) / max(rect.midX, 1)
            let envelope = 0.22 + pow(normalizedDistance, 1.6) * 0.90
            let y = midY + sin(x * frequency + phase + phaseOffset) * amplitude * envelope
            let point = CGPoint(x: x, y: y)

            if xIndex == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        let strokeColor = UIColor(red: 0.13, green: 0.78, blue: 1.0, alpha: alpha)
        strokeColor.setStroke()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        if let context = UIGraphicsGetCurrentContext(), shadowBlur > 0 {
            context.saveGState()
            context.setShadow(
                offset: .zero,
                blur: shadowBlur,
                color: UIColor(red: 0.00, green: 0.67, blue: 1.0, alpha: min(alpha + 0.16, 0.72)).cgColor
            )
            path.stroke()
            context.restoreGState()
            return
        }

        path.stroke()
    }

    private func drawCenterBeam(in rect: CGRect) {
        let centerY = rect.midY
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: centerY))
        path.addLine(to: CGPoint(x: rect.maxX, y: centerY))
        path.lineCapStyle = .round

        let passes: [(CGFloat, CGFloat, CGFloat)] = [
            (16, 0.08, 18),
            (7, 0.20, 10),
            (1.6, 0.72, 5)
        ]

        passes.forEach { lineWidth, alpha, shadowBlur in
            path.lineWidth = lineWidth
            UIColor(red: 0.18, green: 0.83, blue: 1.0, alpha: alpha).setStroke()

            if let context = UIGraphicsGetCurrentContext() {
                context.saveGState()
                context.setShadow(
                    offset: .zero,
                    blur: shadowBlur,
                    color: UIColor(red: 0.00, green: 0.70, blue: 1.0, alpha: alpha + 0.12).cgColor
                )
                path.stroke()
                context.restoreGState()
            } else {
                path.stroke()
            }
        }
    }

    private func drawSparkField(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.saveGState()
        for index in 0..<46 {
            let progress = CGFloat(index) / 45
            let centerGap = abs(progress - 0.5)
            let edgeBoost = min(centerGap * 2.3, 1.0)
            let x = rect.minX + rect.width * progress
            let waveOffset = sin(progress * .pi * 8 + phase * 0.72) * rect.height * 0.13
            let drift = cos(CGFloat(index) * 1.7 + phase * 0.35) * rect.height * 0.07
            let y = rect.midY + waveOffset + drift
            let size = 1.1 + edgeBoost * 1.1
            let alpha = (0.10 + edgeBoost * 0.18) * (0.76 + sin(phase + CGFloat(index)) * 0.24)
            let pointRect = CGRect(x: x - size / 2, y: y - size / 2, width: size, height: size)

            UIColor(red: 0.10, green: 0.72, blue: 1.0, alpha: alpha).setFill()
            context.fillEllipse(in: pointRect)
        }
        context.restoreGState()
    }

    @objc private func tick() {
        phase += 0.06
        setNeedsDisplay()
    }
}

// 小型能量条：作为底部“正在输入”的动态反馈。
private final class VoiceLevelIndicatorView: UIView {
    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0
    private var level: CGFloat = 0.15

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    func setAnimating(_ isAnimating: Bool) {
        if isAnimating {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            displayLink = link
        } else {
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    func update(levels: [Float]) {
        guard !levels.isEmpty else { return }
        let recentLevels = levels.suffix(12)
        let average = recentLevels.reduce(Float(0), +) / Float(recentLevels.count)
        level = CGFloat(min(max(average, 0.10), 1.0))
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard rect.width > 0, rect.height > 0 else { return }

        let barCount = 9
        let spacing: CGFloat = 9
        let barWidth: CGFloat = 4
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
        let startX = rect.midX - totalWidth / 2

        for index in 0..<barCount {
            let wave = (sin(phase + CGFloat(index) * 0.72) + 1) / 2
            let height = 8 + (rect.height - 8) * (0.28 + wave * 0.48 + level * 0.24)
            let x = startX + CGFloat(index) * (barWidth + spacing)
            let y = rect.midY - height / 2
            let path = UIBezierPath(
                roundedRect: CGRect(x: x, y: y, width: barWidth, height: height),
                cornerRadius: barWidth / 2
            )

            let alpha = 0.36 + wave * 0.52
            UIColor(red: 0.20, green: 0.78, blue: 1.0, alpha: alpha).setFill()
            path.fill()
        }
    }

    @objc private func tick() {
        phase += 0.10
        setNeedsDisplay()
    }
}
