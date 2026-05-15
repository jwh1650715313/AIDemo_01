
import UIKit

class EnergyRingView: UIView {

    private var beamLayer: CAShapeLayer?

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let cx = rect.midX
        let cy = rect.height * 0.65

        // 同心椭圆光环（由大到小）
        let rings: [(CGFloat, CGFloat, CGFloat, [CGFloat])] = [
            (130, 26, 0.5, []),          // 最外环，实线
            (100, 20, 0.4, [4, 3]),      // 虚线
            (68,  13, 0.35, [2, 4]),
            (38,  7,  0.5, []),
            (14,  4,  0.65, [])          // 最内环
        ]

        for (i, (rx, ry, alpha, dash)) in rings.enumerated() {
            let blueIntensity = 0.3 + Double(i) * 0.1
            ctx.setStrokeColor(UIColor(
                red: CGFloat(blueIntensity * 0.2),
                green: CGFloat(blueIntensity * 0.5),
                blue: 1,
                alpha: CGFloat(alpha)
            ).cgColor)
            ctx.setLineWidth(i == 0 ? 0.8 : 0.6)

            if !dash.isEmpty {
                ctx.setLineDash(phase: 0, lengths: dash)
            } else {
                ctx.setLineDash(phase: 0, lengths: [])
            }

            ctx.strokeEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        }

        // 中心光点
        ctx.setFillColor(UIColor(red: 0.165, green: 1, blue: 1, alpha: 0.85).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6))

        // 向上光柱
        ctx.setLineDash(phase: 0, lengths: [])
        ctx.setStrokeColor(UIColor(red: 0.165, green: 1, blue: 1, alpha: 0.5).cgColor)
        ctx.setLineWidth(1)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: cx, y: cy - 3))
        ctx.addLine(to: CGPoint(x: cx, y: cy - 55))
        ctx.strokePath()

        // 侧向辅助线
        ctx.setStrokeColor(UIColor(red: 0, green: 0.47, blue: 1, alpha: 0.3).cgColor)
        ctx.setLineWidth(0.5)
        let aux: [(CGPoint, CGPoint)] = [
            (CGPoint(x: cx - 130, y: cy), CGPoint(x: cx - 68, y: cy - 18)),
            (CGPoint(x: cx + 130, y: cy), CGPoint(x: cx + 68, y: cy - 18))
        ]
        for (p1, p2) in aux {
            ctx.beginPath(); ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()
        }
    }
}
