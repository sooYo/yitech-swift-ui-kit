//
//  YTAlertPanelStyle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Draws the complete UI of one alert.
///
/// The library ships `standard`, which is used when a call site does not pass a
/// `view:` style. A call site replaces the whole alert UI by passing its own
/// style to `YTPopup.alert(...)` or `ytAlert(...)`.
///
/// The builder runs inside the popup overlay on the main actor, so it can read
/// the surrounding environment. It owns the panel's background, insets and
/// accessibility; the queue still owns the scrim, the transitions and the
/// dismissal callbacks.
public struct YTAlertPanelStyle {
    private let makeBodyClosure: @MainActor (YTAlertConfiguration) -> AnyView

    /// Creates a panel style from a view builder.
    public init<Body: View>(
        @ViewBuilder _ makeBody: @escaping @MainActor (YTAlertConfiguration) -> Body
    ) {
        self.makeBodyClosure = { configuration in
            AnyView(makeBody(configuration))
        }
    }

    /// The library's standard alert panel.
    public static var standard: YTAlertPanelStyle {
        YTAlertPanelStyle { configuration in
            YTAlertView(configuration: configuration)
        }
    }

    @MainActor
    func makeBody(for configuration: YTAlertConfiguration) -> AnyView {
        makeBodyClosure(configuration)
    }
}
