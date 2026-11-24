//
//  YTPopupOptions.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Presentation options shared by alert and sheet requests.
public struct YTPopupOptions: Sendable {
    /// A per-popup appearance override.
    public enum Style: Sendable {
        /// Overrides the alert appearance.
        case alert(YTAlertStyle)

        /// Overrides the sheet appearance.
        case sheet(YTSheetStyle)
    }

    /// Content alignment and entrance direction.
    public enum Entry: Sendable, Equatable {
        /// Uses the kind default: a sheet slides from the bottom and an alert scales from the center.
        case automatic

        /// Aligns to the bottom edge and slides in from below.
        case bottom

        /// Aligns to the top edge and slides in from above.
        case top

        /// Aligns to the leading edge and slides in from the leading side.
        case leading

        /// Aligns to the trailing edge and slides in from the trailing side.
        case trailing

        /// Centers the content and scales it in.
        case scale

        /// Centers the content and fades it in.
        case fade
    }

    /// Whether tapping the scrim dismisses the popup.
    public var dismissible: Bool

    /// Identifies the popup for de-duplication while it is queued or visible.
    public var key: String?

    /// Marks the popup as owned by a view modifier.
    public var followsOwner: Bool

    /// Overrides the appearance supplied by the popup host.
    public var style: Style?

    /// Overrides the default scrim color of the popup's kind.
    public var scrimColor: Color?

    /// Alignment and entrance direction of the content.
    ///
    /// `.automatic` keeps the kind defaults. Directional entries slide the
    /// content in from the matching edge without a fade; `.scale` and `.fade`
    /// center the content.
    public var entry: Entry

    /// Creates options for a popup request.
    public init(
        dismissible: Bool = true,
        key: String? = nil,
        followsOwner: Bool = false,
        style: Style? = nil,
        scrimColor: Color? = nil,
        entry: Entry = .automatic
    ) {
        self.dismissible = dismissible
        self.key = key
        self.followsOwner = followsOwner
        self.style = style
        self.scrimColor = scrimColor
        self.entry = entry
    }
}
