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
        strokeWidth: CGFloat = 2.3,
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
                ZStack {
                    YTHeartShape()
                        .fill(isLiked ? fillColor : .clear)
                        .overlay {
                            YTHeartShape()
                                .stroke(
                                    isLiked ? likedStrokeColor : strokeColor,
                                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                                )
                        }
//                        .scaleEffect(x: 1.2, y: 1.2)
                        .rotationEffect(heartRotation)
                        .offset(y: -size * 0.04)

                    if animationProgress < 1 && animationTargetLiked {
                        YTLikeBurst(
                            effect: effect,
                            progress: animationProgress,
                            amount: burst / 100,
                            size: size,
                            colors: Self.confettiColors
                        )
                    }
                }
                .frame(width: size, height: size)

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

    private var heartScale: CGFloat {
        guard animationProgress < 1 else { return 1 }
        let pulse = sin(animationProgress * .pi)
        let jelly = sin(animationProgress * 4.5 * .pi) * pow(1 - animationProgress, 1.6)
        let base = animationTargetLiked ? 1 + 0.045 * pulse : 1 + 0.025 * pulse
        return base + 0.016 * jelly
    }

    private var heartRotation: Angle {
        guard animationProgress < 1 else { return .zero }
        let jelly = sin(animationProgress * 4.5 * .pi) * pow(1 - animationProgress, 1.6)
        return .degrees(jelly * 1.4)
    }

    private func handlePress() {
        guard shouldStart() else { return }

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
                guard id == animationID else { return }
                animationProgress = 1
                onAnimationPhaseChange(.progress(100))
                onAnimationPhaseChange(.ended)
                return
            }

            let start = Date()
            var didRevealHeart = false
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_000_000)
                guard !Task.isCancelled, id == animationID else { return }
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
                bloomLayer

                if progress >= 0.8 {
                    let particleProgress = min(1, (progress - 0.8) / 0.2)
                    ForEach(0..<7, id: \.self) { index in
                        let angle = Double(index) * (360 / 7) - 90
                        YTParticlePair(
                            angle: angle,
                            distance: size * 0.92 + 2 + particleProgress * (10 + 12 * amount),
                            progress: particleProgress,
                            firstColor: colors[index % colors.count],
                            secondColor: colors[(index + 3) % colors.count]
                        )
                    }
                }
            } else {
                ForEach(0..<12, id: \.self) { index in
                    let angle = -Double.pi / 2 + (Double(index) / 11 - 0.5) * Double.pi * 1.25
                    let distance = (22 + amount * 22) * progress
                    Circle()
                        .fill(colors[index % colors.count])
                        .frame(width: 4, height: 4)
                        .offset(
                            x: CGFloat(cos(angle) * distance),
                            y: CGFloat(sin(angle) * distance + progress * progress * 18)
                        )
                        .opacity(1 - progress)
                }
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var bloomLayer: some View {
        let maxProgress = 0.62
        let outerRadius = size * 0.92
        let expansion = min(1, progress / maxProgress)
        let radius = size * 0.07 + (outerRadius - size * 0.07) * expansion
        let ringStart = YTLike.revealProgress
        let holeProgress = progress < ringStart
            ? 0
            : min(1, (progress - ringStart) / (maxProgress - ringStart))
        let innerRadius = radius * 0.92 * holeProgress

        YTBloomRing(outerRadius: radius, innerRadius: innerRadius)
            .fill(.purple, style: FillStyle(eoFill: true))
            .opacity(progress < 0.82 ? 1 : 1 - (progress - 0.82) / 0.18)
    }
}

private struct YTBloomRing: Shape {
    let outerRadius: CGFloat
    let innerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.addEllipse(in: CGRect(
            x: center.x - outerRadius,
            y: center.y - outerRadius,
            width: outerRadius * 2,
            height: outerRadius * 2
        ))
        if innerRadius > 0 {
            path.addEllipse(in: CGRect(
                x: center.x - innerRadius,
                y: center.y - innerRadius,
                width: innerRadius * 2,
                height: innerRadius * 2
            ))
        }
        return path
    }
}

private struct YTParticlePair: View {
    let angle: Double
    let distance: CGFloat
    let progress: Double
    let firstColor: Color
    let secondColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(firstColor)
                .frame(width: 4, height: 4)
                .offset(x: cos(angle * .pi / 180) * distance, y: sin(angle * .pi / 180) * distance)
            Circle()
                .fill(secondColor)
                .frame(width: 3, height: 3)
                .offset(x: cos(angle * .pi / 180) * distance * 1.18, y: sin(angle * .pi / 180) * distance * 1.18)
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
            size: 24,
            duration: 1,
            effect: .bloom,
            showsCount: true
        )
        .padding()
    }
}
