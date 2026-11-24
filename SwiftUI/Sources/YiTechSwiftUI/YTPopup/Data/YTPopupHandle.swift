//
//  YTPopupHandle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation

/// A handle returned by the direct popup APIs.
public struct YTPopupHandle: Sendable {
    /// The request identifier used by the queue.
    public let id: UUID

    init(id: UUID) {
        self.id = id
    }

    /// Dismisses the request.
    ///
    /// Safe to call from any thread and more than once. A request that is still
    /// waiting in the sheet queue is removed without animation.
    public func dismiss() {
        YTPopup.dismiss(id)
    }
}
