//  YTToastRequest.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation

internal struct YTToastRequest: Identifiable {
    let id: UUID
    let content: YTToastContent
    let style: YTToastStyle
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        content: YTToastContent,
        style: YTToastStyle,
        duration: TimeInterval
    ) {
        self.id = id
        self.content = content
        self.style = style
        self.duration = duration
    }

    /// Keeps the request identity so the host updates the visible toast in place.
    func replacing(content: YTToastContent, duration: TimeInterval) -> Self {
        YTToastRequest(
            id: id,
            content: content,
            style: style,
            duration: duration
        )
    }
}
