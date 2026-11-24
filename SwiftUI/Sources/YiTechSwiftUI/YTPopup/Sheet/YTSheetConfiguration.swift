//
//  YTSheetConfiguration.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Everything a custom sheet view needs to draw itself.
///
/// The queue builds a configuration for each sheet and hands it to the
/// `YTSheetPanelStyle` supplied by the call site.
public struct YTSheetConfiguration {
    /// Title text supplied by the call site.
    public let title: String

    /// Optional subtitle shown under the title.
    public let subtitle: YTSheetSubtitle?

    /// Optional message; `nil` when the call site supplied none.
    public let message: String?

    /// Optional secondary footer action.
    public let secondary: YTSheetAction?

    /// Optional primary footer action.
    public let primary: YTSheetAction?

    /// Resolved appearance tokens: the per-popup override, otherwise the host style.
    public let style: YTSheetStyle

    /// The content of the sheet.
    public let content: AnyView

    /// Closes the sheet through the queue.
    public let dismiss: () -> Void

    init(
        title: String,
        subtitle: YTSheetSubtitle?,
        message: String?,
        secondary: YTSheetAction?,
        primary: YTSheetAction?,
        style: YTSheetStyle,
        content: AnyView,
        dismiss: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.message = message
        self.secondary = secondary
        self.primary = primary
        self.style = style
        self.content = content
        self.dismiss = dismiss
    }
}
