import UIKit

// 深蓝科幻背景：渐变、网格、轨道线和轻微光斑都集中在这里绘制。
final class GridBackgroundView: UIView {
    private let baseGradientLayer = CAGradientLayer()
    private let gridLayer = CAShapeLayer()
    private let orbitLayer = CAShapeLayer()
    private let starLayer = CAShapeLayer()
    private let topGlowLayer = CAGradientLayer()
    private let centerGlowLayer = CAGradientLayer()
    private let bottomGlowLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureLayers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
        updateVectorPaths()
    }

    private func configureLayers() {
        isUserInteractionEnabled = false
        backgroundColor = UIColor(red: 0.01, green: 0.03, blue: 0.09, alpha: 1.0)

        baseGradientLayer.colors = [
            UIColor(red: 0.01, green: 0.03, blue: 0.10, alpha: 1.0).cgColor,
            UIColor(red: 0.02, green: 0.10, blue: 0.23, alpha: 1.0).cgColor,
            UIColor(red: 0.00, green: 0.02, blue: 0.07, alpha: 1.0).cgColor
        ]
        baseGradientLayer.startPoint = CGPoint(x: 0.15, y: 0.0)
        baseGradientLayer.endPoint = CGPoint(x: 0.85, y: 1.0)
        layer.addSublayer(baseGradientLayer)

        configureGlowLayer(
            topGlowLayer,
            colors: [
                UIColor(red: 0.10, green: 0.44, blue: 1.0, alpha: 0.32),
                UIColor(red: 0.10, green: 0.44, blue: 1.0, alpha: 0.0)
            ]
        )
        configureGlowLayer(
            centerGlowLayer,
            colors: [
                UIColor(red: 0.00, green: 0.72, blue: 1.0, alpha: 0.16),
                UIColor(red: 0.00, green: 0.72, blue: 1.0, alpha: 0.0)
            ]
        )
        configureGlowLayer(
            bottomGlowLayer,
            colors: [
                UIColor(red: 0.18, green: 0.28, blue: 1.0, alpha: 0.18),
                UIColor(red: 0.18, green: 0.28, blue: 1.0, alpha: 0.0)
            ]
        )

        gridLayer.strokeColor = UIColor(red: 0.30, green: 0.70, blue: 1.0, alpha: 0.07).cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 0.7
        layer.addSublayer(gridLayer)

        orbitLayer.strokeColor = UIColor(red: 0.04, green: 0.40, blue: 1.0, alpha: 0.24).cgColor
        orbitLayer.fillColor = UIColor.clear.cgColor
        orbitLayer.lineWidth = 1.2
        layer.addSublayer(orbitLayer)

        starLayer.fillColor = UIColor(red: 0.37, green: 0.78, blue: 1.0, alpha: 0.90).cgColor
        layer.addSublayer(starLayer)
    }

    private func configureGlowLayer(_ glowLayer: CAGradientLayer, colors: [UIColor]) {
        glowLayer.type = .radial
        glowLayer.colors = colors.map(\.cgColor)
        glowLayer.locations = [0.0, 1.0]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.addSublayer(glowLayer)
    }

    private func updateLayerFrames() {
        baseGradientLayer.frame = bounds
        gridLayer.frame = bounds
        orbitLayer.frame = bounds
        starLayer.frame = bounds

        let width = bounds.width
        let height = bounds.height
        topGlowLayer.frame = CGRect(x: width * 0.64, y: height * 0.11, width: width * 0.55, height: width * 0.55)
        centerGlowLayer.frame = CGRect(x: width * 0.20, y: height * 0.32, width: width * 0.70, height: width * 0.70)
        bottomGlowLayer.frame = CGRect(x: -width * 0.18, y: height * 0.76, width: width * 0.62, height: width * 0.62)
    }

    private func updateVectorPaths() {
        gridLayer.path = makeGridPath(in: bounds).cgPath
        orbitLayer.path = makeOrbitPath(in: bounds).cgPath
        starLayer.path = makeStarPath(in: bounds).cgPath
    }

    private func makeGridPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let gridSpacing: CGFloat = 32

        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += gridSpacing
        }

        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += gridSpacing
        }

        return path
    }

    private func makeOrbitPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let radius = max(rect.width, rect.height) * 0.42
        let center = CGPoint(x: rect.width * 1.08, y: rect.height * 0.42)

        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: .pi * 0.82,
            endAngle: .pi * 1.28,
            clockwise: true
        )
        path.addArc(
            withCenter: CGPoint(x: rect.width * -0.16, y: rect.height * 0.88),
            radius: rect.width * 0.52,
            startAngle: -.pi * 0.18,
            endAngle: .pi * 0.22,
            clockwise: true
        )

        return path
    }

    private func makeStarPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let stars: [(CGFloat, CGFloat, CGFloat)] = [
            (0.05, 0.58, 1.8),
            (0.18, 0.22, 1.2),
            (0.31, 0.66, 1.4),
            (0.46, 0.54, 2.0),
            (0.58, 0.79, 1.5),
            (0.82, 0.31, 1.2),
            (0.92, 0.62, 1.7),
            (0.76, 0.72, 1.1)
        ]

        stars.forEach { x, y, size in
            let origin = CGPoint(x: rect.width * x - size / 2, y: rect.height * y - size / 2)
            path.append(UIBezierPath(ovalIn: CGRect(origin: origin, size: CGSize(width: size, height: size))))
        }

        return path
    }
}
