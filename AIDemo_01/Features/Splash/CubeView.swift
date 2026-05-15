

import UIKit

class CubeView: UIView {

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        let cx = rect.midX, cy = rect.midY
        let hw: CGFloat = 38 // 半宽

        // 六边形顶点（等距六方，模拟立方体轮廓）
        let top    = CGPoint(x: cx,      y: cy - hw * 1.1)
        let right  = CGPoint(x: cx + hw, y: cy - hw * 0.35)
        let bRight = CGPoint(x: cx + hw, y: cy + hw * 0.55)
        let bot    = CGPoint(x: cx,      y: cy + hw * 1.1)
        let left   = CGPoint(x: cx - hw, y: cy + hw * 0.55)
        let tLeft  = CGPoint(x: cx - hw, y: cy - hw * 0.35)
        let mid    = CGPoint(x: cx,      y: cy)

        // 顶面
        ctx.beginPath()
        ctx.move(to: top); ctx.addLine(to: right)
        ctx.addLine(to: mid); ctx.addLine(to: tLeft); ctx.closePath()
        ctx.setFillColor(UIColor(red: 0, green: 0.125, blue: 0.502, alpha: 0.95).cgColor)
        ctx.fillPath()

        // 右面
        ctx.beginPath()
        ctx.move(to: mid); ctx.addLine(to: right)
        ctx.addLine(to: bRight); ctx.addLine(to: bot); ctx.closePath()
        ctx.setFillColor(UIColor(red: 0, green: 0.063, blue: 0.376, alpha: 0.9).cgColor)
        ctx.fillPath()

        // 左面
        ctx.beginPath()
        ctx.move(to: tLeft); ctx.addLine(to: mid)
        ctx.addLine(to: bot); ctx.addLine(to: left); ctx.closePath()
        ctx.setFillColor(UIColor(red: 0, green: 0.094, blue: 0.314, alpha: 0.88).cgColor)
        ctx.fillPath()

        // 描边
        let edgeColor = UIColor(red: 0.165, green: 0.678, blue: 1, alpha: 0.85).cgColor
        ctx.setStrokeColor(edgeColor)
        ctx.setLineWidth(1.2)

        let edges: [(CGPoint, CGPoint)] = [
            (top, right), (right, bRight), (bRight, bot),
            (bot, left), (left, tLeft), (tLeft, top),
            (top, mid), (right, mid), (tLeft, mid),
            (mid, bot)
        ]
        for (p1, p2) in edges {
            ctx.beginPath()
            ctx.move(to: p1); ctx.addLine(to: p2)
            ctx.strokePath()
        }

        // 内部十字线（科技感）
        ctx.setStrokeColor(UIColor(red: 0.392, green: 0.784, blue: 1, alpha: 0.3).cgColor)
        ctx.setLineWidth(0.5)
        let innerEdges: [(CGPoint, CGPoint)] = [
            (top, bot), (right, left)
        ]
        for (p1, p2) in innerEdges {
            ctx.beginPath(); ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()
        }

        // 高光圆
        let glowRadius: CGFloat = 10
        let glowRect = CGRect(x: cx - glowRadius, y: top.y + 8, width: glowRadius * 2, height: glowRadius * 2)
        ctx.setFillColor(UIColor(white: 1, alpha: 0.9).cgColor)
        ctx.fillEllipse(in: glowRect)

        // 高光内光晕
        ctx.setFillColor(UIColor(white: 1, alpha: 0.6).cgColor)
        ctx.fillEllipse(in: glowRect.insetBy(dx: 3, dy: 3))
    }
}
