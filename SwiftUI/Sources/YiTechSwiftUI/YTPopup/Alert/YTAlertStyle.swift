//
//  YTAlertStyle.swift
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

/// Appearance of an alert panel.
///
/// The library supplies only a neutral system default. Apps inject their own
/// style through `yPopupHost(alertStyle:sheetStyle:)` or a per-popup
/// `YTPopupOptions.style`.
public struct YTAlertStyle: Sendable {
    /// Background of the panel.
    public var surface: Color

    /// Color of the title.
    public var titleColor: Color

    /// Color of the message.
    public var messageColor: Color

    /// Background of a non-destructive primary button.
    public var primarySurface: Color

    /// Foreground of a non-destructive primary button.
    public var primaryForeground: Color

    /// Background of the secondary button.
    public var secondarySurface: Color

    /// Foreground of the secondary button.
    public var secondaryForeground: Color

    /// Background of a destructive primary button.
    public var destructiveSurface: Color

    /// Foreground of a destructive primary button.
    public var destructiveForeground: Color

    /// Corner radius of the panel.
    public var cornerRadius: CGFloat

    /// Corner radius of the action buttons.
    public var actionCornerRadius: CGFloat

    /// Title font size in points.
    public var titleFontSize: CGFloat

    /// Message font size in points.
    public var messageFontSize: CGFloat

    /// Action button font size in points.
    public var actionFontSize: CGFloat

    /// Creates an alert style.
    public init(
        surface: Color,
        titleColor: Color,
        messageColor: Color,
        primarySurface: Color,
        primaryForeground: Color,
        secondarySurface: Color,
        secondaryForeground: Color,
        destructiveSurface: Color,
        destructiveForeground: Color,
        cornerRadius: CGFloat = 24,
        actionCornerRadius: CGFloat = 14,
        titleFontSize: CGFloat = 17,
        messageFontSize: CGFloat = 13,
        actionFontSize: CGFloat = 15
    ) {
        self.surface = surface
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.primarySurface = primarySurface
        self.primaryForeground = primaryForeground
        self.secondarySurface = secondarySurface
        self.secondaryForeground = secondaryForeground
        self.destructiveSurface = destructiveSurface
        self.destructiveForeground = destructiveForeground
        self.cornerRadius = cornerRadius
        self.actionCornerRadius = actionCornerRadius
        self.titleFontSize = titleFontSize
        self.messageFontSize = messageFontSize
        self.actionFontSize = actionFontSize
    }

    /// Neutral system appearance used until the app injects its own style.
    public static let system = YTAlertStyle(
        surface: ytAlertSystemSurface(),
        titleColor: .primary,
        messageColor: .secondary,
        primarySurface: .primary,
        primaryForeground: ytAlertSystemSurface(),
        secondarySurface: ytAlertSystemFill(),
        secondaryForeground: .primary,
        destructiveSurface: .red,
        destructiveForeground: .white
    )
}

extension EnvironmentValues {
    var ytAlertStyle: YTAlertStyle {
        get { self[YTAlertStyle.EnvironmentKey.self] }
        set { self[YTAlertStyle.EnvironmentKey.self] = newValue }
    }
}

extension YTAlertStyle {
    struct EnvironmentKey: SwiftUI.EnvironmentKey {
        static let defaultValue = YTAlertStyle.system
    }
}

private func ytAlertSystemSurface() -> Color {
    #if os(iOS) || os(visionOS)
    Color(uiColor: .secondarySystemBackground)
    #elseif os(macOS)
    Color(nsColor: .windowBackgroundColor)
    #else
    Color.gray.opacity(0.2)
    #endif
}

private func ytAlertSystemFill() -> Color {
    #if os(iOS) || os(visionOS)
    Color(uiColor: .tertiarySystemFill)
    #elseif os(macOS)
    Color(nsColor: .controlBackgroundColor)
    #else
    Color.gray.opacity(0.3)
    #endif
}
