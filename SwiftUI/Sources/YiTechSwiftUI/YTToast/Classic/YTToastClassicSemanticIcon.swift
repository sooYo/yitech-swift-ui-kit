//  YTToastClassicSemanticIcon.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation
import SwiftUI

/// Hosts a toast's semantic icon and plays the one-shot bloom ring around it.
///
/// The ring is driven by sampled progress instead of an implicit animation:
/// its derived opacity is zero at both sweep endpoints, so a single state jump
/// would interpolate 0 to 0 and the bloom would never become visible.
internal struct YTToastClassicSemanticIcon<Icon: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bloomProgress: CGFloat = 0

    private let color: Color
    private let showDelay: TimeInterval
    private let icon: Icon

    init(
        color: Color,
        showDelay: TimeInterval,
        @ViewBuilder icon: () -> Icon
    ) {
        self.color = color
        self.showDelay = showDelay
        self.icon = icon()
    }

    var body: some View {
        ZStack {
            YTToastClassicBloomRing(color: color, progress: bloomProgress)
                .transaction { $0.animation = nil }
            icon
        }
        .task {
            await runBloom()
        }
    }

    /// Waits for the toast entrance, then samples the ring until the sweep ends.
    @MainActor
    private func runBloom() async {
        guard !reduceMotion else {
            return
        }

        do {
            try await Task.sleep(for: .seconds(max(0, showDelay)))
        } catch {
            return
        }

        bloomProgress = 0
        let start = Date()
        let duration = YTToastClassicBloomCurve.duration

        while !Task.isCancelled {
            bloomProgress = YTToastClassicBloomCurve.progress(
                elapsed: Date().timeIntervalSince(start),
                duration: duration
            )

            guard bloomProgress < 1 else {
                return
            }

            do {
                try await Task.sleep(for: .milliseconds(16))
            } catch {
                return
            }
        }
    }
}
