//
//  YTAlertAction.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation

/// A button in an alert panel.
public struct YTAlertAction {
    /// Label shown inside the button.
    public var title: String

    /// Uses the destructive surface and foreground colors.
    public var isDestructive: Bool

    /// Disables the button and ignores taps.
    public var isDisabled: Bool

    /// Runs when the button is tapped.
    public var handler: () -> Void

    /// Creates an alert action.
    public init(
        title: String,
        isDestructive: Bool = false,
        isDisabled: Bool = false,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
        self.handler = handler
    }
}
