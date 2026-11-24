//
//  YTSheetPanelHost.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Resolves the appearance of one queued sheet and draws the panel the call
/// site asked for.
///
/// The style is resolved from the environment here because the request is built
/// outside the view tree, where environment values are unavailable.
internal struct YTSheetPanelHost: View {
    let title: String
    let subtitle: YTSheetSubtitle?
    let message: String?
    let secondary: YTSheetAction?
    let primary: YTSheetAction?
    let content: () -> AnyView
    let styleOverride: YTSheetStyle?
    let view: YTSheetPanelStyle
    let dismiss: () -> Void

    @Environment(\.ytSheetStyle) private var environmentStyle

    var body: some View {
        let configuration = YTSheetConfiguration(
            title: title,
            subtitle: subtitle,
            message: message,
            secondary: secondary,
            primary: primary,
            style: styleOverride ?? environmentStyle,
            content: content(),
            dismiss: dismiss
        )

        view.makeBody(for: configuration)
    }
}
