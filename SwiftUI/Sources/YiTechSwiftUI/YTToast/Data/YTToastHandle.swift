//  YTToastHandle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation

/// A handle to one shown toast, returned by `YTToast.show`.
public struct YTToastHandle: Sendable {
    /// The request identifier used by the queue.
    public let id: UUID

    init(id: UUID) {
        self.id = id
    }

    /// Dismisses this toast.
    ///
    /// A toast that is still waiting in the queue leaves it without animating.
    /// Calling this more than once, or after the toast left on its own, has no effect.
    @MainActor
    public func dismiss() {
        YTToastRegistry.dismiss(id: id)
    }

    /// Replaces the content of this toast without dismissing and re-presenting it.
    ///
    /// Use it for progress toasts so a value moving from 62% to 80% updates in place
    /// instead of flashing the old toast out and the new one in. The lifetime restarts
    /// from `duration`; pass `nil` to keep the current display duration.
    ///
    /// The in-place change is animated: text cross-fades and the card animates to the
    /// height its new text needs, so a longer or shorter message never snaps.
    @MainActor
    public func update(
        _ content: YTToastContent,
        duration: TimeInterval? = nil
    ) {
        YTToastRegistry.update(id: id, content: content, duration: duration)
    }
}
