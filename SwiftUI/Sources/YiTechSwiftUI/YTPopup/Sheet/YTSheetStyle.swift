//
//  YTSheetStyle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Appearance of a bottom sheet panel.
///
/// The library supplies only a neutral system default. Apps inject their own
/// style through `yPopupHost(alertStyle:sheetStyle:)` or a per-popup
/// `YTPopupOptions.style`.
public struct YTSheetStyle: Sendable {
    /// Background of the panel.
    public var surface: Color

    /// Background of icon buttons and the secondary footer button.
    public var cardSurface: Color

    /// Color of the drag handle and separators.
    public var borderColor: Color

    /// Color of the title.
    public var titleColor: Color

    /// Color of the subtitle.
    public var subtitleColor: Color

    /// Color of the message.
    public var messageColor: Color

    /// Color of the back and close icons.
    public var iconColor: Color

    /// Background of the primary footer button.
    public var primarySurface: Color

    /// Foreground of the primary footer button.
    public var primaryForeground: Color

    /// Foreground of the secondary footer button.
    public var secondaryForeground: Color

    /// Corner radius of the panel.
    public var cornerRadius: CGFloat

    /// Corner radius of the footer buttons.
    public var buttonCornerRadius: CGFloat

    /// Title font size in points.
    public var titleFontSize: CGFloat

    /// Subtitle font size in points.
    public var subtitleFontSize: CGFloat

    /// Message font size in points.
    public var messageFontSize: CGFloat

    /// Footer button font size in points.
    public var buttonFontSize: CGFloat

    /// Creates a sheet style.
    public init(
        surface: Color,
        cardSurface: Color,
        borderColor: Color,
        titleColor: Color,
        subtitleColor: Color,
        messageColor: Color,
        iconColor: Color,
        primarySurface: Color,
        primaryForeground: Color,
        secondaryForeground: Color,
        cornerRadius: CGFloat = 28,
        buttonCornerRadius: CGFloat = 16,
        titleFontSize: CGFloat = 17,
        subtitleFontSize: CGFloat = 11,
        messageFontSize: CGFloat = 13,
        buttonFontSize: CGFloat = 15
    ) {
        self.surface = surface
        self.cardSurface = cardSurface
        self.borderColor = borderColor
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.messageColor = messageColor
        self.iconColor = iconColor
        self.primarySurface = primarySurface
        self.primaryForeground = primaryForeground
        self.secondaryForeground = secondaryForeground
        self.cornerRadius = cornerRadius
        self.buttonCornerRadius = buttonCornerRadius
        self.titleFontSize = titleFontSize
        self.subtitleFontSize = subtitleFontSize
        self.messageFontSize = messageFontSize
        self.buttonFontSize = buttonFontSize
    }

    /// Neutral system appearance used until the app injects its own style.
    public static let system = YTSheetStyle(
        surface: ytSheetSystemSurface(),
        cardSurface: ytSheetSystemFill(),
        borderColor: .secondary.opacity(0.25),
        titleColor: .primary,
        subtitleColor: .secondary,
        messageColor: .secondary,
        iconColor: .secondary,
        primarySurface: .primary,
        primaryForeground: ytSheetSystemSurface(),
        secondaryForeground: .primary
    )
}

extension EnvironmentValues {
    var ytSheetStyle: YTSheetStyle {
        get { self[YTSheetStyle.EnvironmentKey.self] }
        set { self[YTSheetStyle.EnvironmentKey.self] = newValue }
    }
}

extension YTSheetStyle {
    struct EnvironmentKey: SwiftUI.EnvironmentKey {
        static let defaultValue = YTSheetStyle.system
    }
}

private func ytSheetSystemSurface() -> Color {
    #if os(iOS) || os(visionOS)
    Color(uiColor: .secondarySystemBackground)
    #elseif os(macOS)
    Color(nsColor: .windowBackgroundColor)
    #else
    Color.gray.opacity(0.2)
    #endif
}

private func ytSheetSystemFill() -> Color {
    #if os(iOS) || os(visionOS)
    Color(uiColor: .tertiarySystemFill)
    #elseif os(macOS)
    Color(nsColor: .controlBackgroundColor)
    #else
    Color.gray.opacity(0.3)
    #endif
}
