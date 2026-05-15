import UIKit

// App 启动页。
// 这里只负责展示启动视觉和发出完成事件，真正进登录页还是首页交给 AppCoordinator。
final class SplashViewController: UIViewController {
    var onFinish: (() -> Void)?

    private let displayDuration: TimeInterval
    private var finishWorkItem: DispatchWorkItem?
    private var didStartAnimations = false
    private var didFinish = false

    private let gridView = GridBackgroundView()
    private let starFieldView = UIView()
    private let cornerOverlayView = SplashCornerOverlayView()
    private let scanLineView = UIView()
    private let starEmitterLayer = CAEmitterLayer()

    private let hudTopLeftLabel = UILabel()
    private let hudTopRightLabel = UILabel()
    private let hudMidLeftLabel = UILabel()
    private let hudMidRightLabel = UILabel()

    private let ringsStageView = UIView()
    private let ringsView = TopRingsView()
    private let glowView = UIView()
    private let cubeView = CubeView()

    private let dividerLine = UIView()
    private let appNameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let energyView = EnergyRingView()
    private let loadingTrackView = UIView()
    private let loadingFillView = UIView()
    private let bootLabel = UILabel()

    private var loadingFillWidthConstraint: NSLayoutConstraint?

    init(displayDuration: TimeInterval = 2.6, onFinish: (() -> Void)? = nil) {
        self.displayDuration = displayDuration
        self.onFinish = onFinish
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        finishWorkItem?.cancel()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        setupHierarchy()
        setupLayout()
        setupStarEmitter()
        prepareInitialAnimationState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAllAnimationsIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        starEmitterLayer.frame = starFieldView.bounds
        starEmitterLayer.emitterPosition = CGPoint(x: starFieldView.bounds.midX, y: starFieldView.bounds.midY)
        starEmitterLayer.emitterSize = starFieldView.bounds.size

        glowView.layer.cornerRadius = glowView.bounds.width / 2
        loadingTrackView.layer.cornerRadius = loadingTrackView.bounds.height / 2
        loadingFillView.layer.cornerRadius = loadingFillView.bounds.height / 2
    }

    private func configureViews() {
        view.backgroundColor = UIColor(red: 0.00, green: 0.03, blue: 0.08, alpha: 1.0)

        starFieldView.isUserInteractionEnabled = false
        cornerOverlayView.isUserInteractionEnabled = false

        scanLineView.backgroundColor = UIColor(red: 0.00, green: 0.63, blue: 1.00, alpha: 0.58)
        scanLineView.layer.shadowColor = UIColor(red: 0.00, green: 0.72, blue: 1.00, alpha: 0.90).cgColor
        scanLineView.layer.shadowOpacity = 1
        scanLineView.layer.shadowRadius = 10
        scanLineView.layer.shadowOffset = .zero

        configureHUDLabel(hudTopLeftLabel, text: "LINGJING AI\n-- CORE ONLINE", alignment: .left)
        configureHUDLabel(hudTopRightLabel, text: "AI PARTNER\nSYNC 100%", alignment: .right)
        configureHUDLabel(hudMidLeftLabel, text: "INTELLIGENCE\nFOR FUTURE", alignment: .left)
        configureHUDLabel(hudMidRightLabel, text: "SMART\nANSWER", alignment: .right)

        ringsStageView.isUserInteractionEnabled = false
        ringsStageView.backgroundColor = .clear

        ringsView.backgroundColor = .clear
        cubeView.backgroundColor = .clear
        energyView.backgroundColor = .clear

        glowView.backgroundColor = UIColor(red: 0.00, green: 0.62, blue: 1.00, alpha: 0.14)
        glowView.layer.shadowColor = UIColor(red: 0.00, green: 0.72, blue: 1.00, alpha: 1.0).cgColor
        glowView.layer.shadowOpacity = 0.75
        glowView.layer.shadowRadius = 26
        glowView.layer.shadowOffset = .zero

        dividerLine.backgroundColor = UIColor(red: 0.04, green: 0.55, blue: 1.00, alpha: 0.55)
        dividerLine.layer.shadowColor = UIColor(red: 0.00, green: 0.72, blue: 1.00, alpha: 0.80).cgColor
        dividerLine.layer.shadowOpacity = 1
        dividerLine.layer.shadowRadius = 8
        dividerLine.layer.shadowOffset = .zero

        appNameLabel.text = "灵境 AI"
        appNameLabel.font = .systemFont(ofSize: 38, weight: .heavy)
        appNameLabel.textColor = .white
        appNameLabel.textAlignment = .center
        appNameLabel.adjustsFontSizeToFitWidth = true
        appNameLabel.minimumScaleFactor = 0.78

        subtitleLabel.text = "你的智能伙伴，随时为你答疑解惑"
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = UIColor(white: 1.0, alpha: 0.68)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        loadingTrackView.backgroundColor = UIColor(red: 0.08, green: 0.28, blue: 0.52, alpha: 0.45)
        loadingTrackView.clipsToBounds = true

        loadingFillView.backgroundColor = UIColor(red: 0.18, green: 0.95, blue: 1.00, alpha: 0.95)
        loadingFillView.layer.shadowColor = UIColor(red: 0.18, green: 0.95, blue: 1.00, alpha: 1.0).cgColor
        loadingFillView.layer.shadowOpacity = 1
        loadingFillView.layer.shadowRadius = 8
        loadingFillView.layer.shadowOffset = .zero

        bootLabel.text = ">>>  AI 启动中...  <<<"
        bootLabel.font = UIFont(name: "Courier-Bold", size: 11) ?? .monospacedSystemFont(ofSize: 11, weight: .bold)
        bootLabel.textColor = UIColor(red: 0.24, green: 0.82, blue: 1.00, alpha: 0.72)
        bootLabel.textAlignment = .center
    }

    private func configureHUDLabel(_ label: UILabel, text: String, alignment: NSTextAlignment) {
        label.text = text
        label.font = UIFont(name: "Courier", size: 8) ?? .monospacedSystemFont(ofSize: 8, weight: .regular)
        label.textColor = UIColor(red: 0.24, green: 0.72, blue: 1.00, alpha: 0.50)
        label.textAlignment = alignment
        label.numberOfLines = 2
    }

    private func setupHierarchy() {
        [gridView, starFieldView, scanLineView, cornerOverlayView].forEach(view.addSubview)

        [hudTopLeftLabel, hudTopRightLabel, hudMidLeftLabel, hudMidRightLabel].forEach(view.addSubview)

        view.addSubview(ringsStageView)
        [ringsView, glowView, cubeView].forEach(ringsStageView.addSubview)

        [dividerLine, appNameLabel, subtitleLabel, energyView, loadingTrackView, bootLabel].forEach(view.addSubview)
        loadingTrackView.addSubview(loadingFillView)
    }

    private func setupLayout() {
        [
            gridView,
            starFieldView,
            scanLineView,
            cornerOverlayView,
            hudTopLeftLabel,
            hudTopRightLabel,
            hudMidLeftLabel,
            hudMidRightLabel,
            ringsStageView,
            ringsView,
            glowView,
            cubeView,
            dividerLine,
            appNameLabel,
            subtitleLabel,
            energyView,
            loadingTrackView,
            loadingFillView,
            bootLabel
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        let ringsWidth = ringsStageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.62)
        ringsWidth.priority = .defaultHigh

        let energyWidth = energyView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.76)
        energyWidth.priority = .defaultHigh

        let fillWidth = loadingFillView.widthAnchor.constraint(equalToConstant: 0)
        loadingFillWidthConstraint = fillWidth

        NSLayoutConstraint.activate([
            gridView.topAnchor.constraint(equalTo: view.topAnchor),
            gridView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gridView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gridView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            starFieldView.topAnchor.constraint(equalTo: view.topAnchor),
            starFieldView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starFieldView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starFieldView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scanLineView.topAnchor.constraint(equalTo: view.topAnchor),
            scanLineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanLineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scanLineView.heightAnchor.constraint(equalToConstant: 1),

            cornerOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            cornerOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cornerOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cornerOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            hudTopLeftLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            hudTopLeftLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            hudTopLeftLabel.widthAnchor.constraint(equalToConstant: 132),

            hudTopRightLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            hudTopRightLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            hudTopRightLabel.widthAnchor.constraint(equalToConstant: 132),

            hudMidLeftLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            hudMidLeftLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            hudMidLeftLabel.widthAnchor.constraint(equalToConstant: 104),

            hudMidRightLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            hudMidRightLabel.centerYAnchor.constraint(equalTo: hudMidLeftLabel.centerYAnchor),
            hudMidRightLabel.widthAnchor.constraint(equalToConstant: 104),

            ringsStageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            ringsStageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ringsWidth,
            ringsStageView.widthAnchor.constraint(lessThanOrEqualToConstant: 232),
            ringsStageView.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            ringsStageView.heightAnchor.constraint(equalTo: ringsStageView.widthAnchor),

            ringsView.topAnchor.constraint(equalTo: ringsStageView.topAnchor),
            ringsView.leadingAnchor.constraint(equalTo: ringsStageView.leadingAnchor),
            ringsView.trailingAnchor.constraint(equalTo: ringsStageView.trailingAnchor),
            ringsView.bottomAnchor.constraint(equalTo: ringsStageView.bottomAnchor),

            glowView.centerXAnchor.constraint(equalTo: ringsStageView.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: ringsStageView.centerYAnchor),
            glowView.widthAnchor.constraint(equalTo: ringsStageView.widthAnchor, multiplier: 0.54),
            glowView.heightAnchor.constraint(equalTo: glowView.widthAnchor),

            cubeView.centerXAnchor.constraint(equalTo: ringsStageView.centerXAnchor),
            cubeView.centerYAnchor.constraint(equalTo: ringsStageView.centerYAnchor, constant: -2),
            cubeView.widthAnchor.constraint(equalTo: ringsStageView.widthAnchor, multiplier: 0.48),
            cubeView.heightAnchor.constraint(equalTo: cubeView.widthAnchor),

            dividerLine.topAnchor.constraint(equalTo: ringsStageView.bottomAnchor, constant: 16),
            dividerLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dividerLine.widthAnchor.constraint(equalToConstant: 1),
            dividerLine.heightAnchor.constraint(equalToConstant: 26),

            appNameLabel.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 10),
            appNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            appNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            appNameLabel.heightAnchor.constraint(equalToConstant: 48),

            subtitleLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            energyView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            energyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            energyWidth,
            energyView.widthAnchor.constraint(lessThanOrEqualToConstant: 290),
            energyView.heightAnchor.constraint(equalToConstant: 110),

            loadingTrackView.topAnchor.constraint(equalTo: energyView.bottomAnchor, constant: 16),
            loadingTrackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingTrackView.widthAnchor.constraint(equalToConstant: 118),
            loadingTrackView.heightAnchor.constraint(equalToConstant: 2),

            loadingFillView.topAnchor.constraint(equalTo: loadingTrackView.topAnchor),
            loadingFillView.leadingAnchor.constraint(equalTo: loadingTrackView.leadingAnchor),
            loadingFillView.bottomAnchor.constraint(equalTo: loadingTrackView.bottomAnchor),
            fillWidth,

            bootLabel.topAnchor.constraint(equalTo: loadingTrackView.bottomAnchor, constant: 12),
            bootLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            bootLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            bootLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
    }

    private func setupStarEmitter() {
        let cell = CAEmitterCell()
        cell.birthRate = 1.7
        cell.lifetime = 9
        cell.velocity = 5
        cell.velocityRange = 8
        cell.scale = 0.008
        cell.scaleRange = 0.008
        cell.alphaRange = 0.75
        cell.alphaSpeed = -0.04
        cell.color = UIColor(white: 1.0, alpha: 0.95).cgColor
        cell.contents = makeCircleImage(size: 4).cgImage

        starEmitterLayer.emitterShape = .rectangle
        starEmitterLayer.emitterCells = [cell]
        starFieldView.layer.addSublayer(starEmitterLayer)
    }

    private func makeCircleImage(size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        }
    }

    private func prepareInitialAnimationState() {
        [ringsStageView, dividerLine, appNameLabel, subtitleLabel, energyView, loadingTrackView, bootLabel].forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 12)
        }
        cubeView.alpha = 0
        glowView.alpha = 0
    }

    private func startAllAnimationsIfNeeded() {
        guard !didStartAnimations else { return }
        didStartAnimations = true

        view.layoutIfNeeded()
        startScanLineAnimation()
        startLoopingVisualAnimations()
        startEntranceAnimation()
        scheduleFinish()
    }

    private func startScanLineAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.fromValue = -2
        animation.toValue = view.bounds.height + 2
        animation.duration = 2.5
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        scanLineView.layer.add(animation, forKey: "scanLine")
    }

    private func startLoopingVisualAnimations() {
        let ringRotation = CABasicAnimation(keyPath: "transform.rotation.z")
        ringRotation.toValue = CGFloat.pi * 2
        ringRotation.duration = 12
        ringRotation.repeatCount = .infinity
        ringRotation.timingFunction = CAMediaTimingFunction(name: .linear)
        ringsView.layer.add(ringRotation, forKey: "ringRotation")

        UIView.animate(withDuration: 2.8, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut]) {
            self.cubeView.transform = CGAffineTransform(translationX: 0, y: -8)
        }

        UIView.animate(withDuration: 1.9, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut]) {
            self.glowView.transform = CGAffineTransform(scaleX: 1.32, y: 1.32)
            self.glowView.alpha = 0.86
        }

        UIView.animate(withDuration: 1.4, delay: 0.15, options: [.autoreverse, .repeat, .curveEaseInOut]) {
            self.energyView.alpha = 0.62
        }

        UIView.animate(withDuration: 1.1, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut]) {
            self.bootLabel.alpha = 0.34
        }
    }

    private func startEntranceAnimation() {
        UIView.animate(withDuration: 0.7, delay: 0.05, options: [.curveEaseOut]) {
            self.ringsStageView.alpha = 1
            self.ringsStageView.transform = .identity
            self.cubeView.alpha = 1
            self.glowView.alpha = 0.72
        }

        UIView.animate(withDuration: 0.65, delay: 0.28, options: [.curveEaseOut]) {
            [self.dividerLine, self.appNameLabel, self.subtitleLabel, self.energyView, self.loadingTrackView, self.bootLabel].forEach {
                $0.alpha = 1
                $0.transform = .identity
            }
        }

        loadingFillWidthConstraint?.constant = 118
        UIView.animate(withDuration: displayDuration - 0.35, delay: 0.25, options: [.curveEaseInOut]) {
            self.loadingTrackView.layoutIfNeeded()
        }
    }

    private func scheduleFinish() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.finishSplash()
        }
        finishWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: workItem)
    }

    private func finishSplash() {
        guard !didFinish else { return }
        didFinish = true
        onFinish?()
    }
}

private final class SplashCornerOverlayView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(UIColor(red: 0.10, green: 0.48, blue: 1.00, alpha: 0.72).cgColor)
        context.setLineWidth(1.4)
        context.setLineCap(.square)

        let margin: CGFloat = 20
        let topInset = safeAreaInsets.top + 18
        let bottomInset = safeAreaInsets.bottom + 20
        let length: CGFloat = 18

        let points: [(CGPoint, CGPoint, CGPoint)] = [
            (
                CGPoint(x: margin, y: topInset),
                CGPoint(x: margin + length, y: topInset),
                CGPoint(x: margin, y: topInset + length)
            ),
            (
                CGPoint(x: rect.width - margin, y: topInset),
                CGPoint(x: rect.width - margin - length, y: topInset),
                CGPoint(x: rect.width - margin, y: topInset + length)
            ),
            (
                CGPoint(x: margin, y: rect.height - bottomInset),
                CGPoint(x: margin + length, y: rect.height - bottomInset),
                CGPoint(x: margin, y: rect.height - bottomInset - length)
            ),
            (
                CGPoint(x: rect.width - margin, y: rect.height - bottomInset),
                CGPoint(x: rect.width - margin - length, y: rect.height - bottomInset),
                CGPoint(x: rect.width - margin, y: rect.height - bottomInset - length)
            )
        ]

        points.forEach { origin, horizontalEnd, verticalEnd in
            context.move(to: origin)
            context.addLine(to: horizontalEnd)
            context.move(to: origin)
            context.addLine(to: verticalEnd)
        }

        context.strokePath()
    }
}
