//
//  YTLike.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-10-10.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation
import SwiftUI

/// Animated like control with configurable heart styling, particle effect, and progress callbacks
public struct YTLike: View {
    public enum Effect: String, CaseIterable, Sendable {
        case bloom
        case firework
    }

    public enum AnimationPhase: Sendable {
        case started
        /// Progress percentage in the inclusive range 0...100
        case progress(Double)
        case ended
    }

    private static let defaultRed = Color(red: 229 / 255, green: 72 / 255, blue: 77 / 255)
    private static let confettiColors: [Color] = [
        Color(red: 244 / 255, green: 142 / 255, blue: 167 / 255),
        Color(red: 204 / 255, green: 142 / 255, blue: 245 / 255),
        Color(red: 140 / 255, green: 232 / 255, blue: 195 / 255),
        Color(red: 145 / 255, green: 210 / 255, blue: 250 / 255),
        Color(red: 245 / 255, green: 165 / 255, blue: 36 / 255),
        defaultRed,
        Color(red: 159 / 255, green: 199 / 255, blue: 250 / 255)
    ]

    public init(
        initialCount: Int = 1_300,
        size: CGFloat = 44,
        strokeWidth: CGFloat = 1.6,
        strokeColor: Color = .primary,
        likedStrokeColor: Color? = nil,
        fillColor: Color = Color(red: 229 / 255, green: 72 / 255, blue: 77 / 255),
        duration: TimeInterval = 0.42,
        burst: CGFloat = 50,
        effect: Effect = .bloom,
        showsCount: Bool = true,
        shouldStart: @escaping () -> Bool = { true },
        onAnimationPhaseChange: @escaping (AnimationPhase) -> Void = { _ in }
    ) {
        self.initialCount = max(0, initialCount)
        self.size = max(1, size)
        self.strokeWidth = max(0, strokeWidth)
        self.strokeColor = strokeColor
        self.likedStrokeColor = likedStrokeColor ?? YTLike.defaultRed
        self.fillColor = fillColor
        self.duration = max(0, duration)
        self.burst = min(100, max(0, burst))
        self.effect = effect
        self.showsCount = showsCount
        self.shouldStart = shouldStart
        self.onAnimationPhaseChange = onAnimationPhaseChange
    }

    private let initialCount: Int
    private let size: CGFloat
    private let strokeWidth: CGFloat
    private let strokeColor: Color
    private let likedStrokeColor: Color
    private let fillColor: Color
    private let duration: TimeInterval
    private let burst: CGFloat
    private let effect: Effect
    private let showsCount: Bool
    private let shouldStart: () -> Bool
    private let onAnimationPhaseChange: (AnimationPhase) -> Void

    @State private var isLiked = false
    /// Progress drives bloom, particle timing, and the heart's damped jelly motion
    @State private var animationProgress = 1.0
    /// Target state stays separate until bloom starts revealing the heart
    @State private var animationTargetLiked = false
    // Invalidates an older task when user taps again before animation ends
    @State private var animationID = 0
    @State private var animationTask: Task<Void, Never>?

    public var body: some View {
        Button(action: handlePress) {
            HStack(spacing: 7) {
                heart
                    .frame(width: size, height: size)
                    .overlay {
                        if animationProgress < 1, animationTargetLiked {
                            YTLikeBurst(
                                effect: effect,
                                progress: animationProgress,
                                amount: burst / 100,
                                size: size,
                                colors: Self.confettiColors
                            )
                        }
                    }

                if showsCount {
                    countLabel
                        .frame(height: size)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isLiked ? "Unlike" : "Like")
            .accessibilityValue(count.formatted(.number))
            .accessibilityAddTraits(isLiked ? [.isSelected] : [])
        }
        .buttonStyle(.plain)
        .onDisappear {
            animationTask?.cancel()
        }
    }

    private var count: Int {
        initialCount + (isLiked ? 1 : 0)
    }

    private var heart: some View {
        YTHeartShape()
            .fill(isLiked ? fillColor : .clear)
            .overlay {
                YTHeartShape()
                    .stroke(
                        isLiked ? likedStrokeColor : strokeColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                    )
            }
            .scaleEffect(x: heartScaleX, y: heartScaleY)
            .rotationEffect(heartRotation)
            .offset(y: -size * 0.04)
    }

    @ViewBuilder
    private var countLabel: some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            Text(count.formatted(.number))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(count)))
        } else {
            Text(count.formatted(.number))
                .monospacedDigit()
        }
    }

    /// Separates horizontal and vertical scale so pulse becomes visible jelly motion
    private var heartScaleX: CGFloat {
        guard animationProgress < 1 else {
            return 1
        }

        if animationTargetLiked {
            return 1 + likePunchScale + likeStretch
        }

        let pulse = CGFloat(sin(animationProgress * .pi))
        let jelly = CGFloat(sin(animationProgress * 4.5 * .pi) * pow(1 - animationProgress, 1.6))

        return 1 + 0.035 * pulse + 0.065 * jelly
    }

    private var heartScaleY: CGFloat {
        guard animationProgress < 1 else {
            return 1
        }

        if animationTargetLiked {
            return 1 + likePunchScale - likeStretch * 0.85
        }

        let pulse = CGFloat(sin(animationProgress * .pi))
        let jelly = CGFloat(sin(animationProgress * 4.5 * .pi) * pow(1 - animationProgress, 1.6))

        return 1 + 0.055 * pulse - 0.085 * jelly
    }

    /// Like animation uses a short punch instead of a soft sinusoidal pulse
    private var likePunchScale: CGFloat {
        let progress = likeAnimationProgress
        if progress < 0.20 {
            let local = progress / 0.20
            return 0.30 * CGFloat(1 - pow(1 - local, 3))
        }

        if progress < 0.34 {
            let local = (progress - 0.20) / 0.14
            return 0.30 - 0.34 * CGFloat(local)
        }

        if progress < 0.46 {
            let local = (progress - 0.34) / 0.12
            return -0.04 + 0.04 * CGFloat(local)
        }

        return 0
    }

    private var likeStretch: CGFloat {
        let progress = likeAnimationProgress
        if progress < 0.20 {
            let local = progress / 0.20
            return 0.05 * CGFloat(sin(local * .pi))
        }

        if progress < 0.34 {
            let local = (progress - 0.20) / 0.14
            return -0.03 * CGFloat(sin(local * .pi))
        }

        return 0
    }

    private var heartRotation: Angle {
        guard animationProgress < 1 else {
            return .zero
        }
        
        if animationTargetLiked {
            let progress = likeAnimationProgress
            if progress < 0.20 {
                let local = progress / 0.20
                return .degrees(2.8 * sin(local * .pi))
            }

            if progress < 0.34 {
                let local = (progress - 0.20) / 0.14
                return .degrees(-2.8 * sin(local * .pi))
            }

            return .zero
        }

        let jelly = sin(animationProgress * 4.5 * .pi) * pow(1 - animationProgress, 1.6)
        return .degrees(jelly * 1.4)
    }

    /// Waits until bloom ring is nearly hollow before revealing heart motion
    private var likeAnimationProgress: Double {
        let start = Self.likeAnimationStartProgress
        guard animationProgress > start else {
            return 0
        }

        return min(1, (animationProgress - start) / (1 - start))
    }

    private func handlePress() {
        guard shouldStart() else {
            return
        }

        animationTask?.cancel()
        
        let currentTarget = animationProgress < 1 && animationProgress < Self.revealProgress
            ? animationTargetLiked
            : isLiked
        
        let targetLiked = !currentTarget
        animationTargetLiked = targetLiked
        
        if !targetLiked {
            isLiked = false
        }
        
        animationID += 1
        
        let currentAnimationID = animationID
        animationProgress = 0
        
        if duration == 0 {
            isLiked = targetLiked
        }
        
        onAnimationPhaseChange(.started)
        startAnimation(id: currentAnimationID)
    }

    private func startAnimation(id: Int) {
        let animationDuration = duration
        animationTask = Task { @MainActor in
            guard animationDuration > 0 else {
                guard id == animationID else {
                    return
                }

                animationProgress = 1
                onAnimationPhaseChange(.progress(100))
                onAnimationPhaseChange(.ended)
                return
            }

            let start = Date()
            var didRevealHeart = false

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_000_000)
                guard !Task.isCancelled, id == animationID else {
                    return
                }

                let progress = min(1, Date().timeIntervalSince(start) / animationDuration)

                animationProgress = progress

                if !didRevealHeart && progress >= Self.revealProgress {
                    isLiked = animationTargetLiked
                    didRevealHeart = true
                }

                onAnimationPhaseChange(.progress(progress * 100))

                if progress >= 1 {
                    isLiked = animationTargetLiked
                    onAnimationPhaseChange(.ended)
                    return
                }
            }
        }
    }

    fileprivate static let revealProgress = 0.42
    fileprivate static let likeAnimationStartProgress = 0.44
    fileprivate static let particleStartProgress = 0.50
}

private struct YTHeartShape: Shape {
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

private struct YTLikeBurst: View {
    let effect: YTLike.Effect
    let progress: Double
    let amount: CGFloat
    let size: CGFloat
    let colors: [Color]

    var body: some View {
        ZStack {
            if effect == .bloom {
                bloomRing

                if progress >= YTLike.particleStartProgress {
                    let particleProgress = min(
                        1,
                        (progress - YTLike.particleStartProgress)
                            / (1 - YTLike.particleStartProgress)
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
            } else {
                // Stagger sparks around the heart and keep them visible until they spread out
                ForEach(0..<16, id: \.self) { index in
                    let angle = -Double.pi / 2
                        + Double(index) * (2 * Double.pi / 16)
                        + Double((index * 7) % 5 - 2) * 0.07
                    let start = 0.42 + Double(index % 3) * 0.025
                    let particleProgress = min(1, max(0, (progress - start) / (1 - start)))
                    let eased = 1 - pow(1 - particleProgress, 3)
                    let distanceVariation = CGFloat(0.84 + Double((index * 5) % 7) * 0.05)
                    let distance = size * (0.32 + (0.58 + amount * 0.68) * distanceVariation * eased)
                    let gravity = size * 0.12 * particleProgress * particleProgress
                    let fade = min(1, max(0, (particleProgress - 0.55) / 0.45))
                    let opacity = min(1, particleProgress / 0.08) * (1 - fade * fade * (3 - 2 * fade))

                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: max(3, size * 0.09), height: max(3, size * 0.09))
                        .offset(
                            x: cos(angle) * distance,
                            y: sin(angle) * distance + gravity
                        )
                        .opacity(opacity)
                }
            }
        }
        .allowsHitTesting(false)
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

#Preview {
    let duration = 1.0
    VStack {
        YTLike(
            size: 24,
            duration: duration,
            effect: .bloom,
            showsCount: false
        )
        .padding()

        YTLike(
            size: 24,
            duration: duration,
            effect: .firework,
            showsCount: false
        )
        .padding()

        YTLike(
            size: 20,
            duration: 1,
            effect: .bloom,
            showsCount: true
        )
        .padding()
    }
}
