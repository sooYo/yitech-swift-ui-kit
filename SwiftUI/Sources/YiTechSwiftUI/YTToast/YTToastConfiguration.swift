//  YTToastConfiguration.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Appearance and timing defaults used by toast hosts and custom styles.
public struct YTToastConfiguration {
    public struct Text {
        public var font: Font
        public var color: Color

        public init(font: Font = .system(size: 13, weight: .medium), color: Color = Color(red: 0.07, green: 0.07, blue: 0.06)) {
            self.font = font
            self.color = color
        }
    }

    public struct Background {
        public var shape: AnyShape
        public var longFormShape: AnyShape
        public var material: Material
        public var color: Color
        public var borderColor: Color
        public var shadowColor: Color

        public init(
            shape: AnyShape = AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
            longFormShape: AnyShape = AnyShape(RoundedRectangle(cornerRadius: 20, style: .continuous)),
            material: Material = .ultraThinMaterial,
            color: Color = .white.opacity(0.24),
            borderColor: Color = .white.opacity(0.12),
            shadowColor: Color = Color(red: 0.07, green: 0.07, blue: 0.06).opacity(0.16)
        ) {
            self.shape = shape
            self.longFormShape = longFormShape
            self.material = material
            self.color = color
            self.borderColor = borderColor
            self.shadowColor = shadowColor
        }
    }

    public struct Message {
        public var font: Font
        public var color: Color

        public init(font: Font = .system(size: 13), color: Color = .secondary) {
            self.font = font
            self.color = color
        }
    }

    public struct Progress {
        public var tint: Color

        public init(tint: Color = .primary) {
            self.tint = tint
        }
    }

    public struct Interaction {
        /// Controls whether the transparent host layer consumes taps outside the toast.
        public var blocksBackgroundInteraction: Bool

        public init(blocksBackgroundInteraction: Bool = false) {
            self.blocksBackgroundInteraction = blocksBackgroundInteraction
        }
    }

    public struct Animation {
        public struct Set {
            public var transition: AnyTransition
            public var animation: SwiftUI.Animation
            public var duration: TimeInterval

            public init(transition: AnyTransition, animation: SwiftUI.Animation, duration: TimeInterval) {
                self.transition = transition
                self.animation = animation
                self.duration = duration
            }
        }

        public var show: Set
        public var dismiss: Set

        public init(show: Set, dismiss: Set) {
            self.show = show
            self.dismiss = dismiss
        }
    }

    public enum Position {
        case center
        case top
        case bottom
    }

    public var text: Text
    public var message: Message
    public var background: Background
    public var progress: Progress
    public var interaction: Interaction
    public var animation: Animation
    public var position: Position
    public var duration: TimeInterval

    public init(
        text: Text = .init(),
        message: Message = .init(),
        background: Background = .init(),
        progress: Progress = .init(),
        interaction: Interaction = .init(),
        animation: Animation = .init(
            show: .init(
                transition: .scale(scale: 0.92).combined(with: .opacity),
                animation: .spring(response: 0.28, dampingFraction: 0.86),
                duration: 0.28
            ),
            dismiss: .init(
                transition: .scale(scale: 0.96).combined(with: .opacity),
                animation: .easeOut(duration: 0.18),
                duration: 0.18
            )
        ),
        position: Position = .center,
        duration: TimeInterval = 2
    ) {
        self.text = text
        self.message = message
        self.background = background
        self.progress = progress
        self.interaction = interaction
        self.animation = animation
        self.position = position
        self.duration = duration
    }

    public static var `default`: Self {
        .init()
    }
}
