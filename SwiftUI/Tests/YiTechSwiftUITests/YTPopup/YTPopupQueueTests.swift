//
//  YTPopupQueueTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI
import Testing
@testable import YiTechSwiftUI

struct YTPopupQueueTests {
    @Test @MainActor
    func sheetQueueAdvancesInFIFOOrder() {
        let center = makeCenter()

        let first = makeRequest(.sheet)
        let second = makeRequest(.sheet)
        let third = makeRequest(.sheet)

        center.enqueue(first)
        center.enqueue(second)
        center.enqueue(third)

        #expect(center.layers.map(\.request.id) == [first.id])

        dismissAndComplete(first, in: center)
        #expect(center.layers.map(\.request.id) == [second.id])

        dismissAndComplete(second, in: center)
        #expect(center.layers.map(\.request.id) == [third.id])
    }

    @Test @MainActor
    func alertsStackAboveVisibleSheet() {
        let center = makeCenter()

        let sheet = makeRequest(.sheet)
        let firstAlert = makeRequest(.alert)
        let secondAlert = makeRequest(.alert)

        center.enqueue(sheet)
        center.enqueue(firstAlert)
        center.enqueue(secondAlert)

        #expect(center.layers.map(\.request.kind) == [.sheet, .alert, .alert])
        #expect(center.layers.map(\.request.id) == [sheet.id, firstAlert.id, secondAlert.id])
    }

    @Test @MainActor
    func dismissingSheetCascadesToAlertsAboveIt() {
        let center = makeCenter()

        let sheet = makeRequest(.sheet)
        let firstAlert = makeRequest(.alert)
        let secondAlert = makeRequest(.alert)

        center.enqueue(sheet)
        center.enqueue(firstAlert)
        center.enqueue(secondAlert)

        center.requestDismiss(id: sheet.id)
        center.completeRemoval(id: sheet.id)

        #expect(center.layers.map(\.request.id) == [firstAlert.id, secondAlert.id])
        #expect(center.layers.allSatisfy { $0.state == .dismissing })

        center.completeRemoval(id: firstAlert.id)
        center.completeRemoval(id: secondAlert.id)

        #expect(center.layers.isEmpty)
    }

    @Test @MainActor
    func requestDismissAndCompleteRemovalAreIdempotent() {
        let center = makeCenter()
        var dismissCount = 0

        let request = makeRequest(.alert, onDismiss: { dismissCount += 1 })
        center.enqueue(request)

        center.requestDismiss(id: request.id)
        center.requestDismiss(id: request.id)
        center.completeRemoval(id: request.id)
        center.completeRemoval(id: request.id)

        #expect(dismissCount == 1)
        #expect(center.layers.isEmpty)
    }

    @Test @MainActor
    func duplicateKeyIsIgnoredWhileRequestIsAlive() {
        let center = makeCenter()

        let first = makeRequest(.sheet, key: "editor")
        let duplicate = makeRequest(.sheet, key: "editor")

        center.enqueue(first)
        center.enqueue(duplicate)

        #expect(center.layers.map(\.request.id) == [first.id])

        dismissAndComplete(first, in: center)
        center.enqueue(duplicate)

        #expect(center.layers.map(\.request.id) == [duplicate.id])
    }

    @Test @MainActor
    func duplicateKeyInPendingQueueIsIgnored() {
        let center = makeCenter()

        let visible = makeRequest(.sheet)
        let queued = makeRequest(.sheet, key: "queued")
        let duplicate = makeRequest(.sheet, key: "queued")

        center.enqueue(visible)
        center.enqueue(queued)
        center.enqueue(duplicate)

        dismissAndComplete(visible, in: center)
        #expect(center.layers.map(\.request.id) == [queued.id])

        dismissAndComplete(queued, in: center)
        #expect(center.layers.isEmpty)
    }

    @Test @MainActor
    func nextSheetWaitsForRemovalCompletion() {
        let center = makeCenter()

        let first = makeRequest(.sheet)
        let second = makeRequest(.sheet)

        center.enqueue(first)
        center.enqueue(second)

        center.requestDismiss(id: first.id)

        #expect(center.layers.map(\.request.id) == [first.id])
        #expect(center.layers.first?.state == .dismissing)

        center.completeRemoval(id: first.id)

        #expect(center.layers.map(\.request.id) == [second.id])
        #expect(center.layers.first?.state == .presented)
    }

    @Test @MainActor
    func cancellingQueuedSheetCallsBackImmediately() {
        let center = makeCenter()
        var dismissCount = 0

        let visible = makeRequest(.sheet)
        let queued = makeRequest(.sheet, onDismiss: { dismissCount += 1 })

        center.enqueue(visible)
        center.enqueue(queued)

        center.requestDismiss(id: queued.id)

        #expect(dismissCount == 1)
        #expect(center.layers.map(\.request.id) == [visible.id])

        dismissAndComplete(visible, in: center)
        #expect(center.layers.isEmpty)
    }

    @Test @MainActor
    func visibleDismissCallsBackAfterRemoval() {
        let center = makeCenter()
        var dismissCount = 0

        let request = makeRequest(.alert, onDismiss: { dismissCount += 1 })
        center.enqueue(request)

        center.requestDismiss(id: request.id)

        #expect(dismissCount == 0)

        center.completeRemoval(id: request.id)

        #expect(dismissCount == 1)
    }

    @Test @MainActor
    func activationMovesPresentingLayerToPresented() {
        let center = YTPopupCenter()
        center.animatesTransitions = true

        let request = makeRequest(.sheet)
        center.enqueue(request)

        #expect(center.layers.first?.state == .presenting)

        center.activate(id: request.id)

        #expect(center.layers.first?.state == .presented)
    }

    @Test @MainActor
    func dismissAllClearsPendingAndDismissesLayers() {
        let center = makeCenter()
        var pendingDismissCount = 0

        let sheet = makeRequest(.sheet)
        let alert = makeRequest(.alert)
        let pending = makeRequest(.sheet, onDismiss: { pendingDismissCount += 1 })

        center.enqueue(sheet)
        center.enqueue(alert)
        center.enqueue(pending)

        center.dismissAll()

        #expect(pendingDismissCount == 1)
        #expect(center.layers.map(\.request.id) == [sheet.id, alert.id])
        #expect(center.layers.allSatisfy { $0.state == .dismissing })

        center.completeRemoval(id: sheet.id)
        center.completeRemoval(id: alert.id)

        #expect(center.layers.isEmpty)
    }
}

private extension YTPopupQueueTests {
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

    @MainActor
    func dismissAndComplete(_ request: YTPopupRequest, in center: YTPopupCenter) {
        center.requestDismiss(id: request.id)
        center.completeRemoval(id: request.id)
    }
}
