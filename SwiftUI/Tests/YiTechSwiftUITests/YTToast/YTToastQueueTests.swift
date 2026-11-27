//  YTToastQueueTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Testing
@testable import YiTechSwiftUI

struct YTToastQueueTests {
    @Test @MainActor
    func queuedToastsWaitForCurrentDismissalAndAdvanceInFIFOOrder() {
        let center = YTToastCenter()
        let first = makeRequest("First")
        let second = makeRequest("Second")
        let third = makeRequest("Third")

        center.enqueue(first)
        center.enqueue(second)
        center.enqueue(third)

        #expect(center.current?.id == first.id)
        #expect(center.isDismissing)

        center.completeDismissal(id: first.id)
        #expect(center.current?.id == second.id)
        #expect(!center.isDismissing)

        center.dismissCurrent()
        center.completeDismissal(id: second.id)
        #expect(center.current?.id == third.id)
    }

    @Test @MainActor
    func zeroDurationDismissalAdvancesImmediately() {
        let center = YTToastCenter()
        center.animatesTransitions = false
        let first = makeRequest("First")
        let second = makeRequest("Second")

        center.enqueue(first)
        center.enqueue(second)

        #expect(center.current?.id == second.id)
        #expect(!center.isDismissing)
    }

    @MainActor
    private func makeRequest(_ text: String) -> YTToastRequest {
        YTToastRequest(content: .message(text), style: .classic, duration: 1)
    }
}
