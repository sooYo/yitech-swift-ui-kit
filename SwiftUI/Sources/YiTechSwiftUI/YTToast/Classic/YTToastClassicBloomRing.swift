//  YTToastClassicBloomRing.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Pure timing and appearance curve for the classic toast's one-shot bloom ring.
///
/// The ring's opacity is zero at both ends of the sweep, so this curve must be
/// sampled frame by frame. Handing progress to an implicit animation would
/// interpolate the two endpoint opacities (0 to 0) and leave the ring invisible.
internal enum YTToastClassicBloomCurve {
    /// Time the ring takes to expand and fade back out.
    static let duration: TimeInterval = 0.72

    struct Visual: Equatable {
        let opacity: Double
        let lineWidth: CGFloat
        let scale: CGFloat
    }

    /// Maps elapsed time to a sampled sweep progress, clamped to the 0...1 range.
    static func progress(elapsed: TimeInterval, duration: TimeInterval) -> CGFloat {
        guard duration > 0 else {
            return 1
        }

        return CGFloat(min(max(elapsed / duration, 0), 1))
    }

    /// Appearance at a sampled progress, where opacity peaks in the middle of the sweep.
    static func visual(at progress: CGFloat) -> Visual {
        let progress = min(max(progress, 0), 1)
        let easedProgress = 1 - pow(1 - progress, 3)
        let fadeIn = min(progress / 0.14, 1)

        return Visual(
            opacity: 0.62 * Double(fadeIn * (1 - progress)),
            lineWidth: 5.5 - 4.7 * easedProgress,
            scale: 0.58 + 1.08 * easedProgress
        )
    }
}

/// Expands one themed ring around the semantic icon without particle bursts.
struct YTToastClassicBloomRing: View {
    let color: Color
    let progress: CGFloat

    var body: some View {
        let visual = YTToastClassicBloomCurve.visual(at: progress)

        Circle()
            .strokeBorder(
                color.opacity(visual.opacity),
                lineWidth: visual.lineWidth
            )
            .frame(width: 20, height: 20)
            .scaleEffect(visual.scale)
            .allowsHitTesting(false)
    }
}
