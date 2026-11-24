//
//  YTAlertPanelHost.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Resolves the appearance of one queued alert and draws the panel the call
/// site asked for.
///
/// The style is resolved from the environment here because the request is built
/// outside the view tree, where environment values are unavailable.
internal struct YTAlertPanelHost: View {
    let title: String
    let message: String?
    let secondary: YTAlertAction?
    let primary: YTAlertAction
    let hasContent: Bool
    let content: () -> AnyView
    let styleOverride: YTAlertStyle?
    let view: YTAlertPanelStyle
    let dismiss: () -> Void

    @Environment(\.ytAlertStyle) private var environmentStyle

    var body: some View {
        let configuration = YTAlertConfiguration(
            title: title,
            message: message,
            secondary: secondary,
            primary: primary,
            style: styleOverride ?? environmentStyle,
            hasContent: hasContent,
            content: content(),
            dismiss: dismiss
        )

        view.makeBody(for: configuration)
    }
}
