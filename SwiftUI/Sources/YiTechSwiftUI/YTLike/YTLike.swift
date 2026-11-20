//
//  YTLike.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-10-10.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation
import SwiftUI

/// Animated like control with configurable icon styling, particle effect, and progress callbacks
public struct YTLike: View {
    /// `animated` describes this update, not whether the control is currently animating
    public enum LikeValue: Equatable, Sendable {
        case liked(animated: Bool)
        case unliked(animated: Bool)

        public var isLiked: Bool {
            switch self {
            case .liked: return true
            case .unliked: return false
            }
        }

        public var isAnimated: Bool {
            switch self {
            case let .liked(animated), let .unliked(animated):
                return animated
            }
        }
    }

    public enum Shape: String, CaseIterable, Sendable {
        case heart
        case star
        case thumbsUp
    }

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

    /// Bind `likeValue` when the parent owns state and animation intent
    public init(
        initialCount: Int = 0,
        likeValue: Binding<LikeValue>? = nil,
        size: CGFloat = 44,
        shape: Shape = .heart,
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
        let initialLiked = likeValue?.wrappedValue.isLiked ?? false
        self.initialCount = max(0, initialCount)
        self.likeValue = likeValue
        self._isLiked = State(initialValue: initialLiked)
        self._animationTargetLiked = State(initialValue: initialLiked)
        self.size = max(1, size)
        self.shape = shape
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
    private let likeValue: Binding<LikeValue>?
    private let size: CGFloat
    private let shape: Shape
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
    /// Progress drives bloom, particle timing, and the icon's damped jelly motion
    @State private var animationProgress = 1.0
    /// Target state stays separate until bloom starts revealing the icon
    @State private var animationTargetLiked = false
    // Invalidates an older task when user taps again before animation ends
    @State private var animationID = 0
    @State private var animationTask: Task<Void, Never>?

    public var body: some View {
        Button(action: handlePress) {
            HStack(spacing: 7) {
                icon
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
        .onChangeCompatible(of: likeValue?.wrappedValue) { newValue in
            guard let newValue, newValue.isLiked != animationTargetLiked else {
                return
            }

            if newValue.isAnimated {
                startTransition(to: newValue.isLiked)
            } else {
                setLikedWithoutAnimation(newValue.isLiked)
            }
        }
        .onDisappear {
            animationTask?.cancel()
            if let value = likeValue?.wrappedValue {
                isLiked = value.isLiked
                animationTargetLiked = value.isLiked
                animationProgress = 1
            }
        }
    }

    private var count: Int {
        initialCount + (isLiked ? 1 : 0)
    }

    private var icon: some View {
        YTLikeIconShape(shape: shape)
            .fill(isLiked ? fillColor : .clear)
            .overlay {
                YTLikeIconShape(shape: shape)
                    .stroke(
                        isLiked ? likedStrokeColor : strokeColor,
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
                    )
            }
            .scaleEffect(x: iconScaleX, y: iconScaleY)
            .rotationEffect(iconRotation)
            .offset(y: shape == .heart ? -size * 0.04 : 0)
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
    private var iconScaleX: CGFloat {
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

    private var iconScaleY: CGFloat {
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

    private var iconRotation: Angle {
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

    /// Waits until bloom ring is nearly hollow before revealing icon motion
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

        let currentTarget = animationProgress < 1 && animationProgress < Self.revealProgress
            ? animationTargetLiked
            : isLiked

        let targetLiked = !currentTarget
        likeValue?.wrappedValue = targetLiked ? .liked(animated: true) : .unliked(animated: true)
        startTransition(to: targetLiked)
    }

    private func setLikedWithoutAnimation(_ targetLiked: Bool) {
        animationTask?.cancel()
        animationTask = nil
        animationID += 1

        withTransaction(Transaction(animation: nil)) {
            animationTargetLiked = targetLiked
            isLiked = targetLiked
            animationProgress = 1
        }
    }

    private func startTransition(to targetLiked: Bool) {
        animationTask?.cancel()
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
            var didRevealIcon = false

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 16_000_000)
                guard !Task.isCancelled, id == animationID else {
                    return
                }

                let progress = min(1, Date().timeIntervalSince(start) / animationDuration)

                animationProgress = progress

                if !didRevealIcon && progress >= Self.revealProgress {
                    isLiked = animationTargetLiked
                    didRevealIcon = true
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
            shape: .star,
            duration: duration,
            showsCount: false
        )
        .padding()

        YTLike(
            size: 24,
            shape: .thumbsUp,
            duration: duration,
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
