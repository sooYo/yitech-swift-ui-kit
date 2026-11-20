//
//  YTLikeValueTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Testing
@testable import YiTechSwiftUI

#if os(macOS)
import AppKit
import SwiftUI
#endif

struct YTLikeValueTests {
    @Test
    func stateAndAnimationIntentRemainIndependent() {
        let values: [(YTLike.LikeValue, Bool, Bool)] = [
            (.liked(animated: false), true, false),
            (.liked(animated: true), true, true),
            (.unliked(animated: false), false, false),
            (.unliked(animated: true), false, true)
        ]

        for (value, isLiked, isAnimated) in values {
            #expect(value.isLiked == isLiked)
            #expect(value.isAnimated == isAnimated)
        }
    }

    #if os(macOS)
    @Test @MainActor
    func bindingUpdatesAnimateOnlyWhenRequested() {
        let initialModel = LikeModel()
        initialModel.value = .liked(animated: true)
        let initialView = NSHostingView(rootView: LikeTestHost(model: initialModel))
        initialView.frame = NSRect(x: 0, y: 0, width: 120, height: 60)
        initialView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        #expect(initialModel.animationStarts == 0)

        let model = LikeModel()
        let hostingView = NSHostingView(rootView: LikeTestHost(model: model))
        hostingView.frame = NSRect(x: 0, y: 0, width: 120, height: 60)
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        model.value = .liked(animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        #expect(model.animationStarts == 0)

        model.value = .unliked(animated: true)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        #expect(model.animationStarts == 1)

        model.value = .unliked(animated: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        #expect(model.animationStarts == 1)
    }
    #endif
}

#if os(macOS)
@MainActor
private final class LikeModel: ObservableObject {
    @Published var value: YTLike.LikeValue = .unliked(animated: false)
    var animationStarts = 0
}

private struct LikeTestHost: View {
    @ObservedObject var model: LikeModel

    var body: some View {
        YTLike(likeValue: $model.value, duration: 0, onAnimationPhaseChange: { phase in
            if case .started = phase {
                model.animationStarts += 1
            }
        })
    }
}
#endif
