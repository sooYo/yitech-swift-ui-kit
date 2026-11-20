//
//  YTLikeFireworkEffect.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Draws staggered firework sparks
struct YTLikeFireworkEffect: View {
    let progress: Double
    let amount: CGFloat
    let size: CGFloat
    let colors: [Color]

    var body: some View {
        ZStack {
            // Stagger sparks around the icon and keep them visible until they spread out
            ForEach(0 ..< 16, id: \.self) { index in
                let angle = -Double.pi / 2
                    + Double(index) * (2 * Double.pi / 16)
                    + Double((index * 7) % 5 - 2) * 0.07
                let start = 0.42 + Double(index % 3) * 0.025
                let particleProgress = min(1, max(0, (progress - start) / (1 - start)))
                let eased = 1 - pow(1 - particleProgress, 3)
                let distanceVariation = CGFloat(0.84 + Double((index * 5) % 7) * 0.05)
                let distance = size * (0.32 + (0.58 + amount * 0.68) * distanceVariation * eased)
                let gravity = size * 0.12 * particleProgress * particleProgress
                let fade = min(1, max(0, (particleProgress - 0.55) / 0.45))
                let opacity = min(1, particleProgress / 0.08) * (1 - fade * fade * (3 - 2 * fade))

                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: max(3, size * 0.09), height: max(3, size * 0.09))
                    .offset(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance + gravity
                    )
                    .opacity(opacity)
            }
        }
    }
}
