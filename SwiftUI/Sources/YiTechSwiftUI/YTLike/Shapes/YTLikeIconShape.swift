//
//  YTLikeIconShape.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Selects the configured path for the like icon
struct YTLikeIconShape: SwiftUI.Shape {
    let shape: YTLike.Shape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .heart:
            YTHeartShape().path(in: rect)
        case .star:
            YTStarShape().path(in: rect)
        case .thumbsUp:
            YTThumbsUpShape().path(in: rect)
        }
    }
}
