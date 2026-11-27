//  YTToastLifetimeTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation
import Testing
@testable import YiTechSwiftUI

struct YTToastLifetimeTests {
    /// A toast promoted after the previous one left must still auto-dismiss.
    ///
    /// The original timer hung off the content view's onAppear, but SwiftUI reuses
    /// the container when the host swaps request identities, so the promoted toast
    /// never started a timer and stayed on screen forever.
    @Test @MainActor
    func promotedToastStartsItsOwnLifetime() async {
        let center = YTToastCenter()
        // Skipping transitions promotes the next request synchronously.
        center.animatesTransitions = false
        let first = YTToastRequest(content: .message("First"), style: .classic, duration: 5)
        let second = YTToastRequest(content: .message("Second"), style: .classic, duration: 0.15)

        center.enqueue(first)
        center.enqueue(second)
        #expect(center.current?.id == second.id)
        #expect(!center.isDismissing)

        await waitUntil(timeout: 3) { center.current == nil }
        #expect(center.current == nil)
        #expect(!center.isDismissing)
    }

    @Test @MainActor
    func zeroDurationKeepsToastUntilDismissed() async {
        let center = YTToastCenter()
        center.animatesTransitions = false
        let request = YTToastRequest(content: .message("Sticky"), style: .classic, duration: 0)

        center.enqueue(request)
        try? await Task.sleep(for: .milliseconds(300))
        #expect(center.current?.id == request.id)

        center.dismiss(id: request.id)
        #expect(center.current == nil)
    }

    /// Polls instead of sleeping a fixed time so slow CI hosts cannot fail the test.
    @MainActor
    private func waitUntil(
        timeout: TimeInterval,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
