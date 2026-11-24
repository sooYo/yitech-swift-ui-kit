//
//  YTAlertConfiguration.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Everything a custom alert view needs to draw itself.
///
/// The queue builds a configuration for each alert and hands it to the
/// `YTAlertPanelStyle` supplied by the call site.
public struct YTAlertConfiguration {
    /// Title text supplied by the call site.
    public let title: String

    /// Optional message; `nil` when the call site supplied none.
    public let message: String?

    /// Optional secondary action. Its handler closes the alert before running.
    public let secondary: YTAlertAction?

    /// Primary action. Its handler closes the alert before running.
    public let primary: YTAlertAction

    /// Resolved appearance tokens: the per-popup override, otherwise the host style.
    public let style: YTAlertStyle

    /// Whether the call site supplied a content slot.
    public let hasContent: Bool

    /// The content slot; `EmptyView` when `hasContent` is `false`.
    public let content: AnyView

    /// Closes the alert through the queue.
    ///
    /// The supplied actions already close the alert before running their own
    /// handler, so this is only needed for extra close controls.
    public let dismiss: () -> Void

    init(
        title: String,
        message: String?,
        secondary: YTAlertAction?,
        primary: YTAlertAction,
        style: YTAlertStyle,
        hasContent: Bool,
        content: AnyView,
        dismiss: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.secondary = secondary
        self.primary = primary
        self.style = style
        self.hasContent = hasContent
        self.content = content
        self.dismiss = dismiss
    }
}
