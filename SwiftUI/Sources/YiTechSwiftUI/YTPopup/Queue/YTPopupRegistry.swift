//
//  YTPopupRegistry.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation

/// Routes direct popup requests to the most recently active popup host.
///
/// Requests that arrive before any host is installed are held in a queue and
/// flushed into the host when it appears.
@MainActor
internal enum YTPopupRegistry {
    private struct Host {
        weak var center: YTPopupCenter?
        var lastActive: Int
    }

    private static var hosts: [Host] = []
    private static var nextActiveOrder = 0
    private static var pending: [YTPopupRequest] = []

    // MARK: - Host Lifecycle

    /// Registers a host and flushes requests that arrived before it existed.
    static func install(_ center: YTPopupCenter) {
        if let index = hosts.firstIndex(where: { $0.center === center }) {
            hosts[index].lastActive = makeOrder()
        } else {
            hosts.append(Host(center: center, lastActive: makeOrder()))
        }

        flushPending(into: center)
    }

    /// Removes a host from routing and clears popups tied to it.
    static func uninstall(_ center: YTPopupCenter) {
        hosts.removeAll { host in
            guard let installed = host.center else {
                return true
            }
            return installed === center
        }

        center.clearImmediately()
    }

    /// Marks a host as the most recently active one.
    static func markActive(_ center: YTPopupCenter) {
        guard let index = hosts.firstIndex(where: { $0.center === center }) else {
            return
        }

        hosts[index].lastActive = makeOrder()
    }

    // MARK: - Requests

    /// Enqueues a request, hopping to the main actor when needed.
    nonisolated static func enqueueFromAnyThread(_ request: YTPopupRequest) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                enqueue(request)
            }
        } else {
            Task { @MainActor in
                enqueue(request)
            }
        }
    }

    /// Dismisses a request, hopping to the main actor when needed.
    nonisolated static func dismissFromAnyThread(id: UUID) {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                dismiss(id: id)
            }
        } else {
            Task { @MainActor in
                dismiss(id: id)
            }
        }
    }

    static func enqueue(_ request: YTPopupRequest) {
        if let center = activeCenter {
            center.enqueue(request)
            return
        }

        guard !isPendingKeyAlive(request.options.key) else {
            return
        }

        pending.append(request)
    }

    static func dismiss(id: UUID) {
        if let index = pending.firstIndex(where: { $0.id == id }) {
            let request = pending.remove(at: index)
            request.onDismiss?()
        }

        for host in hosts {
            host.center?.requestDismiss(id: id)
        }
    }

    /// Removes all hosts and queued requests. Used by tests to isolate state.
    static func reset() {
        hosts.removeAll()
        pending.removeAll()
        nextActiveOrder = 0
    }

    // MARK: - Helpers

    private static var activeCenter: YTPopupCenter? {
        hosts
            .compactMap { host -> (center: YTPopupCenter, order: Int)? in
                guard let center = host.center else {
                    return nil
                }
                return (center, host.lastActive)
            }
            .max { $0.order < $1.order }?
            .center
    }

    private static func flushPending(into center: YTPopupCenter) {
        guard !pending.isEmpty else {
            return
        }

        let requests = pending
        pending.removeAll()
        requests.forEach { center.enqueue($0) }
    }

    private static func isPendingKeyAlive(_ key: String?) -> Bool {
        guard let key else {
            return false
        }

        return pending.contains { $0.options.key == key }
    }

    private static func makeOrder() -> Int {
        defer { nextActiveOrder += 1 }
        return nextActiveOrder
    }
}
