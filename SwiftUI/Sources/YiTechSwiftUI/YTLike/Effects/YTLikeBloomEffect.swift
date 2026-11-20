//
//  YTLikeBloomEffect.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Draws the bloom ring and paired particles
struct YTLikeBloomEffect: View {
    let progress: Double
    let amount: CGFloat
    let size: CGFloat
    let colors: [Color]

    private static let particleStartProgress = 0.50

    var body: some View {
        ZStack {
            bloomRing

            if progress >= Self.particleStartProgress {
                let particleProgress = min(
                    1,
                    (progress - Self.particleStartProgress)
                        / (1 - Self.particleStartProgress)
                )
                ForEach(0..<7, id: \.self) { index in
                    let angle = Double(index) * (360 / 7) - 90
                    YTParticlePair(
                        angle: angle,
                        distance: size * 0.70 + 1,
                        travelDistance: 8 + 10 * amount,
                        progress: particleProgress,
                        firstColor: colors[index % colors.count],
                        secondColor: colors[(index + 3) % colors.count]
                    )
                }
            }
        }
    }

    /// Bloom ring follows staged scale, border, color, and opacity timing
    private var bloomRing: some View {
        let radius = size * 0.92
        let p = progress
        let fillEnd = 0.30

        let scale: CGFloat
        if p < fillEnd {
            let local = p / fillEnd
            let eased = BezierEasing.value(local, 0.25, 0.8, 0.35, 1)
            scale = CGFloat(0.15 + 0.85 * eased)
        } else {
            let local = (p - fillEnd) / (1 - fillEnd)
            let eased = BezierEasing.value(local, 0.25, 0.8, 0.35, 1)
            scale = CGFloat(1 + 0.12 * eased)
        }

        let borderWidth: CGFloat
        if p < fillEnd {
            borderWidth = radius
        } else if p < 0.75 {
            let local = (p - fillEnd) / (0.75 - fillEnd)
            let eased = BezierEasing.value(local, 0.25, 0.8, 0.35, 1)
            borderWidth = radius - (radius - radius * 2 / 17) * CGFloat(eased)
        } else {
            let local = (p - 0.75) / 0.25
            let eased = BezierEasing.value(local, 0.25, 0.8, 0.35, 1)
            borderWidth = radius * 2 / 17 * CGFloat(1 - eased)
        }

        let color: Color
        if p < fillEnd {
            let local = p / fillEnd
            let eased = BezierEasing.value(local, 0.25, 0.8, 0.35, 1)
            color = Self.bloomColor(eased)
        } else {
            color = Self.bloomPurple
        }

        let opacity: Double
        if p < 0.75 {
            opacity = 1
        } else {
            let local = (p - 0.75) / 0.25
            let eased = BezierEasing.value(local, 0.25, 0.8, 0.35, 1)
            opacity = 1 - eased
        }

        return Circle()
            .strokeBorder(color, lineWidth: borderWidth)
            .frame(width: radius * 2, height: radius * 2)
            .scaleEffect(scale)
            .opacity(opacity)
    }

    private static let bloomPurple = Color(red: 204 / 255, green: 142 / 255, blue: 245 / 255)

    private static func bloomColor(_ progress: Double) -> Color {
        let t = min(1, max(0, progress))
        let red = 229 + (204 - 229) * t
        let green = 72 + (142 - 72) * t
        let blue = 77 + (245 - 77) * t

        return Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
}

private enum BezierEasing {
    static func value(
        _ progress: Double,
        _ x1: Double,
        _ y1: Double,
        _ x2: Double,
        _ y2: Double
    ) -> Double {
        let x = min(1, max(0, progress))
        var t = x

        // Newton-Raphson solves cubic x(t), then cubic y(t) gives eased progress
        for _ in 0..<8 {
            let currentX = cubic(t, 0, x1, x2, 1)
            let derivative = cubicDerivative(t, 0, x1, x2, 1)
            guard abs(derivative) > 0.0001 else { break }
            t = min(1, max(0, t - (currentX - x) / derivative))
        }

        return cubic(t, 0, y1, y2, 1)
    }

    private static func cubic(_ t: Double, _ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> Double {
        let inverse = 1 - t
        return inverse * inverse * inverse * p0
            + 3 * inverse * inverse * t * p1
            + 3 * inverse * t * t * p2
            + t * t * t * p3
    }

    private static func cubicDerivative(_ t: Double, _ p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> Double {
        let inverse = 1 - t
        return 3 * inverse * inverse * (p1 - p0)
            + 6 * inverse * t * (p2 - p1)
            + 3 * t * t * (p3 - p2)
    }
}

private struct YTParticlePair: View {
    let angle: Double
    let distance: CGFloat
    let travelDistance: CGFloat
    let progress: Double
    let firstColor: Color
    let secondColor: Color

    var body: some View {
        let movement = CGFloat(BezierEasing.value(progress, 0.15, 0.75, 0.25, 1))
        let currentDistance = distance + travelDistance * movement
        let gravity = CGFloat(progress * progress * 6)

        ZStack {
            Circle()
                .fill(firstColor)
                .frame(width: 4, height: 4)
                .offset(
                    x: cos(angle * .pi / 180) * currentDistance,
                    y: sin(angle * .pi / 180) * currentDistance + gravity
                )
            Circle()
                .fill(secondColor)
                .frame(width: 3, height: 3)
                .offset(
                    x: cos(angle * .pi / 180) * currentDistance * 1.12,
                    y: sin(angle * .pi / 180) * currentDistance * 1.12 + gravity
                )
        }
        .opacity(1 - progress)
    }
}
