//
//  YTPopupKind.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation

/// The two presentation forms managed by the popup queue.
public enum YTPopupKind: Sendable {
    /// A centered modal that stacks above any visible sheet.
    case alert

    /// A bottom panel; the queue presents one sheet at a time.
    case sheet
}
