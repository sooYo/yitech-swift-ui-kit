//  YTToastCenter.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Combine
import SwiftUI

/// Owns a single visible toast and advances requests after its exit completes.
@MainActor
internal final class YTToastCenter: ObservableObject {
    @Published private(set) var current: YTToastRequest?
    @Published private(set) var isDismissing = false
    private var pending: [YTToastRequest] = []
    private var lifetimeTask: Task<Void, Never>?
    private var dismissalTask: Task<Void, Never>?

    /// How long an in-place update takes to morph the visible toast into new content.
    ///
    /// Text cross-fades and, since the card is not height-locked, a message that wraps
    /// differently resizes the card over the same animation instead of snapping.
    private static let updateAnimation: Animation = .easeInOut(duration: 0.3)

    var animatesTransitions = true

    func enqueue(_ request: YTToastRequest) {
        pending.append(request)

        guard current != nil else {
            advance()
            return
        }

        dismissCurrent()
    }

    /// Whether the request with `id` is visible or still waiting in the queue.
    func owns(id: UUID) -> Bool {
        current?.id == id || pending.contains { $0.id == id }
    }

    /// Dismisses the request with `id`.
    ///
    /// A request that is still waiting in the queue leaves it immediately without
    /// animating; a visible request runs its dismissal transition.
    func dismiss(id: UUID) {
        if let index = pending.firstIndex(where: { $0.id == id }) {
            pending.remove(at: index)
            return
        }

        guard current?.id == id else {
            return
        }

        dismissCurrent()
    }

    /// Replaces the content of the request with `id` in place, restarting its lifetime.
    ///
    /// The request keeps its identity, so the host updates the visible toast instead
    /// of dismissing it and presenting a new one. Pass `duration` to change the
    /// remaining display time; `nil` keeps the current duration.
    func update(id: UUID, content: YTToastContent, duration: TimeInterval?) {
        if let index = pending.firstIndex(where: { $0.id == id }) {
            let request = pending[index]
            pending[index] = request.replacing(
                content: content,
                duration: duration ?? request.duration
            )
            return
        }

        guard let current, current.id == id, !isDismissing else {
            return
        }

        let updated = current.replacing(
            content: content,
            duration: duration ?? current.duration
        )
        withAnimation(Self.updateAnimation) {
            self.current = updated
        }
        startLifetime(for: updated)
    }

    func dismissCurrent() {
        guard let current, !isDismissing else {
            return
        }

        lifetimeTask?.cancel()
        isDismissing = true
        let duration = current.style.configuration.animation.dismiss.duration
        let id = current.id

        guard animatesTransitions, duration > 0 else {
            completeDismissal(id: id)
            return
        }

        dismissalTask?.cancel()
        dismissalTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else {
                return
            }
            completeDismissal(id: id)
        }
    }

    func clearImmediately() {
        lifetimeTask?.cancel()
        dismissalTask?.cancel()
        current = nil
        pending.removeAll()
        isDismissing = false
    }

    func completeDismissal(id: UUID) {
        guard current?.id == id, isDismissing else {
            return
        }

        current = nil
        isDismissing = false
        dismissalTask = nil
        advance()
    }

    private func advance() {
        guard current == nil, !pending.isEmpty else {
            return
        }

        let next = pending.removeFirst()
        current = next
        startLifetime(for: next)
    }

    /// Starts the auto-dismiss timer as soon as a request takes the stage.
    ///
    /// The timer must not depend on the content view's `onAppear`: when a request is
    /// promoted after the previous toast left, SwiftUI reuses the container and does
    /// not call `onAppear` again, which left the promoted toast on screen forever.
    /// A duration of 0 keeps the toast until it is dismissed or replaced.
    private func startLifetime(for request: YTToastRequest) {
        lifetimeTask?.cancel()
        lifetimeTask = nil

        let duration = request.duration
        guard duration > 0 else {
            return
        }

        let id = request.id
        lifetimeTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(duration))
            } catch {
                return
            }

            guard !Task.isCancelled, current?.id == id, !isDismissing else {
                return
            }

            dismissCurrent()
        }
    }
}
