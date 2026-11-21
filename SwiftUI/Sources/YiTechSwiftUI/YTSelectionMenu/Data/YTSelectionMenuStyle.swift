//
//  YTSelectionMenuStyle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Appearance and fixed geometry of the menu-owned shape and selection decoration
public struct YTSelectionMenuStyle {
    /// Fixed sizes keep the menu center unchanged when content or selection changes; oversized content is clipped
    public struct Dimensions {
        /// Width and height in points for a capsule or menu row
        public struct Size {
            /// Width in points
            public var width: Double

            /// Height in points
            public var height: Double

            /// Creates a size with independent width and height
            public init(_ width: Double, _ height: Double) {
                self.width = width
                self.height = height
            }

            /// Creates a square size with equal width and height
            public init(size: Double) {
                self.width = size
                self.height = size
            }
        }

        /// Collapsed shape and content size in points; custom triggers should fit within it
        public var capsule: Size

        /// Row size in points; a visible highlighter reserves 32 points on its trailing edge
        public var row: Size

        public init(
            capsule: Size = .init(140, 38),
            row: Size = .init(188, 34)
        ) {
            self.row = row
            self.capsule = capsule
        }
    }

    /// Appearance of the expanded panel's background shape
    public struct Panel {
        /// Shadow applied only while the panel is expanded
        public struct Shadow {
            /// Shadow color
            public var color: Color

            /// Shadow blur radius in points
            public var radius: Double

            /// Horizontal shadow offset in points
            public var x: Double

            /// Vertical shadow offset in points
            public var y: Double

            public init(
                color: Color = .black.opacity(0.18),
                radius: Double = 12,
                x: Double = 0,
                y: Double = 6
            ) {
                self.x = x
                self.y = y
                self.color = color
                self.radius = radius
            }
        }

        /// Panel corner radius in points, clamped to 0...40; `nil` uses the menu's `corner` argument
        public var cornerRadius: Double?

        /// Expanded panel shadow; `nil` removes it
        public var shadow: Shadow?

        /// Background color of the shared shape while expanded
        public var backgroundColor: Color

        public init(
            backgroundColor: Color = Color(red: 0.13, green: 0.14, blue: 0.17),
            cornerRadius: Double? = nil,
            shadow: Shadow? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.cornerRadius = cornerRadius
            self.shadow = shadow
        }
    }

    /// Selected-row background and icon applied outside the row content builder
    public struct Highlighter {
        /// Selected-row icon in a material circle; its primary color follows light and dark mode
        public var icon: Image

        /// Controls both the selected-row icon and highlight background
        public var isVisible: Bool

        /// Background drawn behind the selected row content when `isVisible` is true
        public var backgroundColor: Color

        public init(
            icon: Image = Image(systemName: "checkmark"),
            isVisible: Bool = true,
            backgroundColor: Color = .white.opacity(0.08)
        ) {
            self.icon = icon
            self.isVisible = isVisible
            self.backgroundColor = backgroundColor
        }
    }

    /// Expanded panel background, corners, and shadow
    public var panel: Panel

    /// Selected-row icon and background behavior
    public var highlighter: Highlighter

    /// Background color of the shared shape while collapsed, behind capsule content
    public var capsuleBackgroundColor: Color

    /// Defaults: 140×38 capsule and 188×34 row; panel adds 12-point padding and 2-point row spacing
    public var dimensions: Dimensions

    public init(
        panel: Panel = .init(),
        dimensions: Dimensions = .init(),
        highlighter: Highlighter = .init(),
        capsuleBackgroundColor: Color = Color(red: 0.13, green: 0.14, blue: 0.17)
    ) {
        self.panel = panel
        self.dimensions = dimensions
        self.highlighter = highlighter
        self.capsuleBackgroundColor = capsuleBackgroundColor
    }
}
