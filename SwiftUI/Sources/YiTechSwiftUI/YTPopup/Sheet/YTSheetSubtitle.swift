//
//  YTSheetSubtitle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// A sheet subtitle with an optional color dot.
public struct YTSheetSubtitle: Sendable {
    /// Text shown under the title.
    public var text: String

    /// Optional dot drawn before the text.
    public var dotColor: Color?

    /// Creates a subtitle.
    public init(text: String, dotColor: Color? = nil) {
        self.text = text
        self.dotColor = dotColor
    }
}
