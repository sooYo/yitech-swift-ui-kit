//
//  YTSheetPanelStyle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Draws the complete UI of one sheet.
///
/// The library ships `standard`, which is used when a call site does not pass a
/// `view:` style. A call site replaces the whole sheet chrome by passing its own
/// style to `YTPopup.sheet(...)` or `ytSheet(...)`.
///
/// The builder runs inside the popup overlay on the main actor, so it can read
/// the surrounding environment. It owns the drag handle, background, insets,
/// scrolling and accessibility; the queue still owns the scrim, the transitions
/// and the dismissal callbacks.
public struct YTSheetPanelStyle {
    private let makeBodyClosure: @MainActor (YTSheetConfiguration) -> AnyView

    /// Creates a panel style from a view builder.
    public init<Body: View>(
        @ViewBuilder _ makeBody: @escaping @MainActor (YTSheetConfiguration) -> Body
    ) {
        self.makeBodyClosure = { configuration in
            AnyView(makeBody(configuration))
        }
    }

    /// The library's standard sheet panel.
    public static var standard: YTSheetPanelStyle {
        YTSheetPanelStyle { configuration in
            YTSheetView(configuration: configuration)
        }
    }

    @MainActor
    func makeBody(for configuration: YTSheetConfiguration) -> AnyView {
        makeBodyClosure(configuration)
    }
}
