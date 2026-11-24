//
//  YTSheetAction.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation

/// A footer button in a sheet panel.
public struct YTSheetAction {
    /// Label shown inside the button.
    public var title: String

    /// Disables the button and ignores taps.
    public var isEnabled: Bool

    /// Runs when the button is tapped.
    public var action: () -> Void

    /// Creates a sheet action.
    public init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
}
