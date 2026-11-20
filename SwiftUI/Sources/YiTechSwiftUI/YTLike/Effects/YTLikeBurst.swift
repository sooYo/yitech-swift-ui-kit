//
//  YTLikeBurst.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Selects the configured effect around the like icon
struct YTLikeBurst: View {
    let effect: YTLike.Effect
    let progress: Double
    let amount: CGFloat
    let size: CGFloat
    let colors: [Color]

    var body: some View {
        ZStack {
            if effect == .bloom {
                YTLikeBloomEffect(
                    progress: progress,
                    amount: amount,
                    size: size,
                    colors: colors
                )
            } else {
                YTLikeFireworkEffect(
                    progress: progress,
                    amount: amount,
                    size: size,
                    colors: colors
                )
            }
        }
        .allowsHitTesting(false)
    }
}
