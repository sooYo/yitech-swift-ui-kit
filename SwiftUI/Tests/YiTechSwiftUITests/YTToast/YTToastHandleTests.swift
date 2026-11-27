//  YTToastHandleTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation
import Testing
@testable import YiTechSwiftUI

struct YTToastHandleTests {
    @Test @MainActor
    func updateReplacesContentOfVisibleToast() {
        let center = YTToastCenter()
        center.animatesTransitions = false
        YTToastRegistry.install(center)
        defer { YTToastRegistry.uninstall(center) }

        let handle = YTToast.show(.progress("Syncing", value: 0.62), duration: 5)
        #expect(center.current?.id == handle.id)

        handle.update(.progress("Syncing", value: 0.8))

        #expect(center.current?.id == handle.id)
        if case .progress(_, let value, _)? = center.current?.content {
            #expect(abs(value - 0.8) < 0.0001)
        } else {
            Issue.record("expected an updated progress content")
        }
    }

    @Test @MainActor
    func dismissClosesVisibleToast() {
        let center = YTToastCenter()
        center.animatesTransitions = false
        YTToastRegistry.install(center)
        defer { YTToastRegistry.uninstall(center) }

        _ = YTToast.show(.success("Saved"), duration: 5)
        #expect(center.current != nil)

        YTToast.dismiss()
        #expect(center.current == nil)
    }

    @Test @MainActor
    func queuedToastCanBeDismissedBeforeItAppears() {
        let center = YTToastCenter()
        YTToastRegistry.install(center)
        defer { YTToastRegistry.uninstall(center) }

        let first = YTToast.show(.message("First"), duration: 5)
        let second = YTToast.show(.message("Second"), duration: 5)
        #expect(center.current?.id == first.id)

        second.dismiss()
        center.completeDismissal(id: first.id)
        #expect(center.current == nil)
    }
}
