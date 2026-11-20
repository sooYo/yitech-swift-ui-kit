//
//  YTHeartShape.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Draws the heart icon path
struct YTHeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // 1. 起点：底部中心。稍微上提一点点 (0.85)，让心形更紧凑，不至于太尖长
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.85))

        // 2. 左下曲线：从底部到左侧边缘
        path.addCurve(
            to: CGPoint(x: w * 0.05, y: h * 0.35), // 左侧边缘点，比原来更靠外(0.05)，更高(0.35)更饱满
            control1: CGPoint(x: w * 0.45, y: h * 0.8), // 底部向外扩张，让下半部分“胖”起来
            control2: CGPoint(x: w * 0.05, y: h * 0.55) // 左侧边缘向下膨胀
        )

        // 3. 左上曲线：从左侧边缘到顶部中心凹陷
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.25), // 顶部凹陷中心，下移(从0.2到0.25)，增加圆润感
            control1: CGPoint(x: w * 0.05, y: h * 0.12), // 左侧顶部向上撑起
            control2: CGPoint(x: w * 0.35, y: h * 0.12) // 靠近中缝的顶部向内收
        )

        // 4. 右上曲线：从顶部中心凹陷到右侧边缘（严格镜像于左上曲线）
        path.addCurve(
            to: CGPoint(x: w * 0.95, y: h * 0.35), // 右侧边缘点 (1 - 0.05)
            control1: CGPoint(x: w * 0.65, y: h * 0.12), // (1 - 0.35)
            control2: CGPoint(x: w * 0.95, y: h * 0.12) // (1 - 0.05)
        )

        // 5. 右下曲线：从右侧边缘回到起点（严格镜像于左下曲线）
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.85),
            control1: CGPoint(x: w * 0.95, y: h * 0.55), // (1 - 0.05)
            control2: CGPoint(x: w * 0.55, y: h * 0.8) // (1 - 0.25)
        )

        path.closeSubpath()

        return path
    }
}
