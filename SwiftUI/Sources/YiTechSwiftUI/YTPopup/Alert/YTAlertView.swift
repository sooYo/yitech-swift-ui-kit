//
//  YTAlertView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// A modal alert panel with an optional content slot.
///
/// The panel owns the title, message, and buttons. The content slot sits between
/// the message and the buttons, so custom input such as a text field keeps the
/// panel's standard chrome.
public struct YTAlertView<Content: View>: View {
    private let title: String
    private let message: String?
    private let secondary: YTAlertAction?
    private let primary: YTAlertAction
    private let styleOverride: YTAlertStyle?
    private let hasContent: Bool
    private let content: () -> Content

    @Environment(\.ytAlertStyle) private var environmentStyle

    /// Creates an alert without a content slot.
    public init(
        title: String,
        message: String? = nil,
        secondary: YTAlertAction? = nil,
        primary: YTAlertAction,
        style: YTAlertStyle? = nil
    ) where Content == EmptyView {
        self.title = title
        self.message = message
        self.secondary = secondary
        self.primary = primary
        self.styleOverride = style
        self.hasContent = false
        self.content = { EmptyView() }
    }

    /// Creates an alert with a content slot.
    public init(
        title: String,
        message: String? = nil,
        secondary: YTAlertAction? = nil,
        primary: YTAlertAction,
        style: YTAlertStyle? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.message = message
        self.secondary = secondary
        self.primary = primary
        self.styleOverride = style
        self.hasContent = true
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(title)
                        .font(.system(size: resolvedStyle.titleFontSize, weight: .bold))
                        .foregroundStyle(resolvedStyle.titleColor)
                        .multilineTextAlignment(.center)

                    Spacer()
                }

                if let message, !message.isEmpty {
                    Text(message)
                        .font(.system(size: resolvedStyle.messageFontSize))
                        .foregroundStyle(resolvedStyle.messageColor)
                        .multilineTextAlignment(.center)
                }
            }

            if hasContent {
                content()
            }

            HStack(spacing: 10) {
                if let secondary {
                    actionButton(secondary, isSecondary: true)
                }

                actionButton(primary, isSecondary: false)
            }
            .padding(.top, 6)
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(
            resolvedStyle.surface,
            in: RoundedRectangle(cornerRadius: resolvedStyle.cornerRadius, style: .continuous)
        )
    }

    private var resolvedStyle: YTAlertStyle {
        styleOverride ?? environmentStyle
    }

    private func actionButton(_ action: YTAlertAction, isSecondary: Bool) -> some View {
        Button(action.title, action: action.handler)
            .font(.system(size: resolvedStyle.actionFontSize, weight: .semibold))
            .foregroundStyle(
                isSecondary
                    ? resolvedStyle.secondaryForeground
                    : (action.isDestructive
                        ? resolvedStyle.destructiveForeground
                        : resolvedStyle.primaryForeground)
            )
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                isSecondary
                    ? resolvedStyle.secondarySurface
                    : (action.isDestructive
                        ? resolvedStyle.destructiveSurface
                        : resolvedStyle.primarySurface),
                in: RoundedRectangle(
                    cornerRadius: resolvedStyle.actionCornerRadius,
                    style: .continuous
                )
            )
            .disabled(action.isDisabled)
            .opacity(action.isDisabled ? 0.45 : 1)
    }
}
