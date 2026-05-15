//
//  TopRingsView.swift
//  AIDemo_01
//
//  Created by kwmin on 2026/5/15.
//

import UIKit

class TopRingsView: UIView {
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let cx = rect.midX, cy = rect.midY

        let rings: [(CGFloat, CGFloat, [CGFloat])] = [
            (105, 0.5, [3, 5]),
            (90,  0.7, [8, 4]),
            (75,  0.4, [2, 6]),
            (60,  0.45, [4, 3])
        ]

        for (r, alpha, dash) in rings {
            ctx.setStrokeColor(UIColor(red: 0.1, green: 0.416, blue: 1, alpha: CGFloat(alpha)).cgColor)
            ctx.setLineWidth(0.7)
            ctx.setLineDash(phase: 0, lengths: dash)
            ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        // 顶部指示器
        ctx.setLineDash(phase: 0, lengths: [])
        ctx.setStrokeColor(UIColor(red: 0.1, green: 0.416, blue: 1, alpha: 0.8).cgColor)
        ctx.setLineWidth(1.5)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: cx, y: cy - 105))
        ctx.addLine(to: CGPoint(x: cx, y: cy - 80))
        ctx.strokePath()

        ctx.setFillColor(UIColor(red: 0.165, green: 1, blue: 1, alpha: 0.9).cgColor)
        ctx.fillEllipse(in: CGRect(x: cx - 2.5, y: cy - 107.5, width: 5, height: 5))
    }
}
