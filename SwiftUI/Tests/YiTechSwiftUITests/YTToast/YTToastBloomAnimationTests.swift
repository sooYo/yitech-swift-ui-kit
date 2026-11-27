//  YTToastBloomAnimationTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation
import Testing
@testable import YiTechSwiftUI

struct YTToastBloomAnimationTests {
    /// 60fps cadence, matching the loop that drives the ring.
    private static let frameInterval: TimeInterval = 1.0 / 60

    @Test
    func sweepProducesIntermediateFrames() {
        let duration = YTToastClassicBloomCurve.duration
        var samples: [CGFloat] = []
        var elapsed: TimeInterval = 0

        while elapsed < duration {
            samples.append(YTToastClassicBloomCurve.progress(elapsed: elapsed, duration: duration))
            elapsed += Self.frameInterval
        }
        samples.append(YTToastClassicBloomCurve.progress(elapsed: duration, duration: duration))

        #expect(samples.first == 0)
        #expect(samples.last == 1)
        #expect(samples.contains { $0 > 0.2 && $0 < 0.8 })
        #expect(zip(samples, samples.dropFirst()).allSatisfy { previous, next in previous <= next })
    }

    @Test
    func sweepCompletesImmediatelyWithoutDuration() {
        #expect(YTToastClassicBloomCurve.progress(elapsed: 0, duration: 0) == 1)
        #expect(YTToastClassicBloomCurve.progress(elapsed: 5, duration: 0.72) == 1)
        #expect(YTToastClassicBloomCurve.progress(elapsed: -1, duration: 0.72) == 0)
    }

    /// Regression guard for the bug this animation shipped with: opacity is zero at
    /// both sweep endpoints, so animating the single 0 to 1 state jump implicitly
    /// interpolates 0 to 0 and never shows the ring. Only sampled frames are visible.
    @Test
    func bloomIsVisibleBetweenSweepEndpoints() {
        let duration = YTToastClassicBloomCurve.duration
        #expect(YTToastClassicBloomCurve.visual(at: 0).opacity == 0)
        #expect(YTToastClassicBloomCurve.visual(at: 1).opacity == 0)

        var opacities: [Double] = []
        var elapsed: TimeInterval = 0

        while elapsed <= duration {
            let progress = YTToastClassicBloomCurve.progress(elapsed: elapsed, duration: duration)
            opacities.append(YTToastClassicBloomCurve.visual(at: progress).opacity)
            elapsed += Self.frameInterval
        }

        #expect((opacities.max() ?? 0) > 0.4)
    }

    @Test
    func ringExpandsWhileFadingOut() {
        let start = YTToastClassicBloomCurve.visual(at: 0)
        let middle = YTToastClassicBloomCurve.visual(at: 0.3)
        let end = YTToastClassicBloomCurve.visual(at: 1)

        #expect(start.scale < middle.scale)
        #expect(middle.scale < end.scale)
        #expect(start.lineWidth > middle.lineWidth)
        #expect(middle.lineWidth > end.lineWidth)
        #expect(abs(end.scale - 1.66) < 0.001)
        #expect(abs(end.lineWidth - 0.8) < 0.001)
    }
}
