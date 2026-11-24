//
//  YTPopupRegistryTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI
import Testing
@testable import YiTechSwiftUI

@Suite(.serialized)
struct YTPopupRegistryTests {
    @Test @MainActor
    func pendingRequestsFlushWhenHostInstalls() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let request = makeRequest(.sheet)

        YTPopupRegistry.enqueueFromAnyThread(request)

        let center = makeCenter()
        #expect(center.layers.isEmpty)

        YTPopupRegistry.install(center)

        #expect(center.layers.map(\.request.id) == [request.id])
    }

    @Test @MainActor
    func requestsRouteToMostRecentlyActiveHost() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let firstCenter = makeCenter()
        let secondCenter = makeCenter()

        YTPopupRegistry.install(firstCenter)
        YTPopupRegistry.install(secondCenter)

        let firstRequest = makeRequest(.alert)
        YTPopupRegistry.enqueueFromAnyThread(firstRequest)
        #expect(secondCenter.layers.map(\.request.id) == [firstRequest.id])

        YTPopupRegistry.markActive(firstCenter)

        let secondRequest = makeRequest(.alert)
        YTPopupRegistry.enqueueFromAnyThread(secondRequest)
        #expect(firstCenter.layers.map(\.request.id) == [secondRequest.id])
    }

    @Test @MainActor
    func uninstalledHostStopsReceivingRequests() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)
        YTPopupRegistry.uninstall(center)

        let request = makeRequest(.sheet)
        YTPopupRegistry.enqueueFromAnyThread(request)
        #expect(center.layers.isEmpty)

        let replacement = makeCenter()
        YTPopupRegistry.install(replacement)

        #expect(replacement.layers.map(\.request.id) == [request.id])
    }

    @Test @MainActor
    func directAlertQueuesWithoutHostAndDismisses() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        var dismissCount = 0
        let handle = YTPopup.alert(
            "Title",
            primaryTitle: "OK",
            onDismiss: { dismissCount += 1 }
        )

        let center = makeCenter()
        YTPopupRegistry.install(center)

        #expect(center.layers.map(\.request.id) == [handle.id])

        handle.dismiss()
        #expect(center.layers.first?.state == .dismissing)

        center.completeRemoval(id: handle.id)

        #expect(dismissCount == 1)
        #expect(center.layers.isEmpty)
    }

    @Test @MainActor
    func pendingRequestsDeduplicateByKey() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let first = makeRequest(.sheet, key: "new-category")
        let duplicate = makeRequest(.sheet, key: "new-category")

        YTPopupRegistry.enqueueFromAnyThread(first)
        YTPopupRegistry.enqueueFromAnyThread(duplicate)

        let center = makeCenter()
        YTPopupRegistry.install(center)

        #expect(center.layers.count == 1)
        #expect(center.layers.first?.request.id == first.id)
    }

    @Test @MainActor
    func dismissingPendingRequestCallsBack() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        var dismissCount = 0
        let request = makeRequest(.sheet, onDismiss: { dismissCount += 1 })

        YTPopupRegistry.enqueueFromAnyThread(request)
        YTPopupRegistry.dismissFromAnyThread(id: request.id)

        #expect(dismissCount == 1)

        let center = makeCenter()
        YTPopupRegistry.install(center)

        #expect(center.layers.isEmpty)
    }
}

private extension YTPopupRegistryTests {
    @MainActor
    func makeCenter() -> YTPopupCenter {
        let center = YTPopupCenter()
        center.animatesTransitions = false
        return center
    }

    @MainActor
    func makeRequest(
        _ kind: YTPopupKind,
        key: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> YTPopupRequest {
        YTPopupRequest(
            kind: kind,
            options: .init(key: key),
            makeContent: {
                AnyView(EmptyView())
            },
            onDismiss: onDismiss
        )
    }
}
