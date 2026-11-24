//
//  YTSheetView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// A bottom sheet panel with a drag handle, header, scrolling content, and footer actions.
///
/// The panel sits inside the safe area and only its background extends to the
/// bottom edge of the screen. Content keeps its natural height and becomes
/// scrollable when the available space is smaller.
public struct YTSheetView<Content: View>: View {
    private let title: String
    private let subtitle: YTSheetSubtitle?
    private let message: String?
    private let onBack: (() -> Void)?
    private let onClose: () -> Void
    private let secondary: YTSheetAction?
    private let primary: YTSheetAction?
    private let styleOverride: YTSheetStyle?
    private let backAccessibilityLabel: String
    private let closeAccessibilityLabel: String
    private let content: () -> Content

    @Environment(\.ytSheetStyle) private var environmentStyle

    @State private var contentHeight: CGFloat = 0

    /// Creates a sheet panel.
    public init(
        title: String,
        subtitle: YTSheetSubtitle? = nil,
        message: String? = nil,
        onBack: (() -> Void)? = nil,
        onClose: @escaping () -> Void,
        secondary: YTSheetAction? = nil,
        primary: YTSheetAction? = nil,
        style: YTSheetStyle? = nil,
        backAccessibilityLabel: String = "Back",
        closeAccessibilityLabel: String = "Close",
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.message = message
        self.onBack = onBack
        self.onClose = onClose
        self.secondary = secondary
        self.primary = primary
        self.styleOverride = style
        self.backAccessibilityLabel = backAccessibilityLabel
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(resolvedStyle.borderColor)
                .frame(width: 36, height: 4)
                .frame(height: 20)

            header

            ScrollView(.vertical, showsIndicators: false) {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        contentHeight = height
                    }
            }
            .frame(maxHeight: contentHeight > 0 ? contentHeight : nil)
            .ytSheetScrollBehavior()

            footer
        }
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .frame(maxWidth: 460)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: resolvedStyle.cornerRadius,
                topTrailingRadius: resolvedStyle.cornerRadius
            )
            .fill(resolvedStyle.surface)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var resolvedStyle: YTSheetStyle {
        styleOverride ?? environmentStyle
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let onBack {
                iconButton("chevron.left", accessibility: backAccessibilityLabel, action: onBack)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: resolvedStyle.titleFontSize, weight: .bold))
                    .foregroundStyle(resolvedStyle.titleColor)
                    .lineLimit(1)

                if let subtitle {
                    HStack(spacing: 6) {
                        if let dotColor = subtitle.dotColor {
                            Circle()
                                .fill(dotColor)
                                .frame(width: 10, height: 10)
                        }

                        Text(subtitle.text)
                            .font(.system(size: resolvedStyle.subtitleFontSize))
                            .foregroundStyle(resolvedStyle.subtitleColor)
                            .lineLimit(1)
                    }
                }

                if let message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: resolvedStyle.messageFontSize))
                        .foregroundStyle(resolvedStyle.messageColor)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            iconButton("xmark", accessibility: closeAccessibilityLabel, action: onClose)
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private var footer: some View {
        if secondary != nil || primary != nil {
            HStack(spacing: 10) {
                if let secondary {
                    YTSheetButton(action: secondary, style: .secondary, appearance: resolvedStyle)
                        .frame(width: 120)
                }

                if let primary {
                    YTSheetButton(action: primary, style: .primary, appearance: resolvedStyle)
                }
            }
            .padding(.top, 18)
        }
    }

    private func iconButton(
        _ systemImage: String,
        accessibility: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(resolvedStyle.iconColor)
                .frame(width: 32, height: 32)
                .background(resolvedStyle.cardSurface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibility))
    }
}

private extension View {
    @ViewBuilder
    func ytSheetScrollBehavior() -> some View {
        #if os(iOS)
        scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        #elseif os(macOS)
        scrollBounceBehavior(.basedOnSize)
        #else
        self
        #endif
    }
}
