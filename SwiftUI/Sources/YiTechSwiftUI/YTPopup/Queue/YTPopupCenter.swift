//
//  YTPopupCenter.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Combine
import SwiftUI

/// Owns the visible popup layers of one host and the pending sheet queue.
///
/// Layers are ordered from bottom to top. A sheet is always the bottom layer and
/// at most one sheet is visible; alerts stack above it. Queue advancement happens
/// only after the current layer's removal animation completes.
@MainActor
internal final class YTPopupCenter: ObservableObject {
    /// Visible layers from bottom to top.
    @Published private(set) var layers: [YTPopupLayer] = []

    /// Sheets waiting for the visible sheet to leave.
    private var pendingSheets: [YTPopupRequest] = []

    /// Tests disable transitions so queue advancement can be checked synchronously.
    var animatesTransitions = true

    /// Whether the host should stop hit testing its base content.
    var hasPopups: Bool {
        !layers.isEmpty
    }

    // MARK: - Queue

    /// Adds a request to the queue.
    ///
    /// A sheet is presented immediately when no sheet is visible, otherwise it
    /// waits in FIFO order. Alerts are always stacked immediately. A request whose
    /// `key` is still alive, including one that is only waiting in the queue, is ignored.
    func enqueue(_ request: YTPopupRequest) {
        if let key = request.options.key, isKeyAlive(key) {
            return
        }

        switch request.kind {
        case .sheet:
            if layers.contains(where: { $0.request.kind == .sheet }) {
                pendingSheets.append(request)
            } else {
                present(request)
            }
        case .alert:
            present(request)
        }
    }

    /// Requests dismissal of the request with `id`.
    ///
    /// Queued sheets are removed immediately and receive their `onDismiss`
    /// callback right away. Visible layers enter `.dismissing`, animate out, and
    /// complete through `completeRemoval(id:)`. Calling this more than once for the
    /// same request has no additional effect.
    func requestDismiss(id: UUID) {
        if let index = pendingSheets.firstIndex(where: { $0.id == id }) {
            let request = pendingSheets.remove(at: index)
            request.onDismiss?()
            return
        }

        guard let index = layers.firstIndex(where: { $0.id == id }),
              layers[index].state != .dismissing else {
            return
        }

        let animation = removalAnimation(for: layers[index].request.kind)

        animateRemoval(id: id, animation: animation) {
            self.layers[index].state = .dismissing
        }
    }

    /// Completes a removal after its animation finished.
    ///
    /// Pops the layer, cascades dismissal to alerts above a sheet, invokes the
    /// request's `onDismiss`, and advances the pending sheet queue.
    func completeRemoval(id: UUID) {
        guard let index = layers.firstIndex(where: { $0.id == id }),
              layers[index].state == .dismissing else {
            return
        }

        let layer = layers.remove(at: index)

        if layer.request.kind == .sheet {
            let alertIDs = layers
                .filter { $0.request.kind == .alert && $0.state != .dismissing }
                .map(\.id)

            for alertID in alertIDs {
                requestDismiss(id: alertID)
            }
        }

        layer.request.onDismiss?()

        if layer.request.kind == .sheet {
            advanceSheetQueue()
        }
    }

    /// Requests dismissal of every visible and queued popup.
    func dismissAll() {
        let pending = pendingSheets
        pendingSheets.removeAll()
        pending.forEach { $0.onDismiss?() }

        let ids = layers.map(\.id)
        for id in ids {
            requestDismiss(id: id)
        }
    }

    /// Removes every layer and queued request without animation, invoking callbacks.
    func clearImmediately() {
        let requests = layers.map(\.request) + pendingSheets
        layers.removeAll()
        pendingSheets.removeAll()
        requests.forEach { $0.onDismiss?() }
    }

    // MARK: - Presentation

    private func present(_ request: YTPopupRequest) {
        let layer = YTPopupLayer(
            id: request.id,
            request: request,
            content: request.makeContent(),
            state: .presenting
        )

        // The layer is inserted empty so the content can animate in from the
        // requested edge once the view exists. The root view calls `activate`
        // from `onAppear` to start that second phase.
        insert(layer)

        if !animatesTransitions {
            markPresented(id: request.id)
        }
    }

    /// Starts the entrance animation for a layer that is already in the view tree.
    func activate(id: UUID) {
        guard let index = layers.firstIndex(where: { $0.id == id }),
              layers[index].state == .presenting else {
            return
        }

        let animation = insertionAnimation(for: layers[index].request.kind)

        if animatesTransitions {
            withAnimation(animation) {
                markPresented(id: id)
            }
        } else {
            markPresented(id: id)
        }
    }

    private func markPresented(id: UUID) {
        guard let index = layers.firstIndex(where: { $0.id == id }),
              layers[index].state == .presenting else {
            return
        }

        layers[index].state = .presented
    }

    private func insert(_ layer: YTPopupLayer) {
        if layer.request.kind == .sheet {
            layers.insert(layer, at: 0)
        } else {
            layers.append(layer)
        }
    }

    private func advanceSheetQueue() {
        guard !pendingSheets.isEmpty else {
            return
        }

        let next = pendingSheets.removeFirst()
        present(next)
    }

    // MARK: - Keys

    private func isKeyAlive(_ key: String) -> Bool {
        layers.contains { $0.request.options.key == key }
            || pendingSheets.contains { $0.options.key == key }
    }

    // MARK: - Animation

    private func insertionAnimation(for kind: YTPopupKind) -> Animation {
        switch kind {
        case .alert:
            return .spring(response: 0.55, dampingFraction: 0.55)
        case .sheet:
            return .spring(response: 0.4, dampingFraction: 0.85)
        }
    }

    private func removalAnimation(for kind: YTPopupKind) -> Animation {
        .easeIn(duration: 0.2)
    }

    private func animateRemoval(
        id: UUID,
        animation: Animation,
        _ body: () -> Void
    ) {
        guard animatesTransitions else {
            body()
            return
        }

        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            withAnimation(animation) {
                body()
            } completion: {
                MainActor.assumeIsolated {
                    self.completeRemoval(id: id)
                }
            }
        } else {
            withAnimation(animation) {
                body()
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(220))
                self.completeRemoval(id: id)
            }
        }
    }
}
