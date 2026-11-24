//
//  YTPopupLayer.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// One rendered popup in the queue.
internal struct YTPopupLayer: Identifiable {
    /// Where the layer is in its insertion/removal lifecycle.
    enum State: Equatable {
        case presenting
        case presented
        case dismissing
    }

    let id: UUID
    var request: YTPopupRequest

    /// The view built once on the main actor when the layer is presented.
    let content: AnyView

    var state: State
}
