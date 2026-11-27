//  YTToastRegistry.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Foundation

/// Routes requests to a SwiftUI-installed host without consulting UIKit windows.
@MainActor
internal enum YTToastRegistry {
    private struct Host {
        weak var center: YTToastCenter?
        var lastActive: Int
    }

    private static var hosts: [Host] = []
    private static var nextActiveOrder = 0
    private static var pending: [YTToastRequest] = []

    static func install(_ center: YTToastCenter) {
        if let index = hosts.firstIndex(where: { $0.center === center }) {
            hosts[index].lastActive = makeOrder()
        } else {
            hosts.append(Host(center: center, lastActive: makeOrder()))
        }

        let requests = pending
        pending.removeAll()
        requests.forEach { center.enqueue($0) }
    }

    static func uninstall(_ center: YTToastCenter) {
        hosts.removeAll { $0.center == nil || $0.center === center }
        center.clearImmediately()
    }

    static func markActive(_ center: YTToastCenter) {
        guard let index = hosts.firstIndex(where: { $0.center === center }) else {
            return
        }
        hosts[index].lastActive = makeOrder()
    }

    static func enqueue(_ request: YTToastRequest) {
        guard let center = activeCenter else {
            pending.append(request)
            return
        }
        center.enqueue(request)
    }

    /// Dismisses the request with `id`, whether it is visible or still queued.
    static func dismiss(id: UUID) {
        if let center = center(owning: id) {
            center.dismiss(id: id)
            return
        }

        pending.removeAll { $0.id == id }
    }

    /// Updates the content of the request with `id` without re-presenting it.
    static func update(id: UUID, content: YTToastContent, duration: TimeInterval?) {
        if let center = center(owning: id) {
            center.update(id: id, content: content, duration: duration)
            return
        }

        guard let index = pending.firstIndex(where: { $0.id == id }) else {
            return
        }

        let request = pending[index]
        pending[index] = request.replacing(
            content: content,
            duration: duration ?? request.duration
        )
    }

    /// Dismisses the toast the most recently active host is showing.
    static func dismissCurrent() {
        activeCenter?.dismissCurrent()
    }

    private static func center(owning id: UUID) -> YTToastCenter? {
        hosts.compactMap(\.center).first { $0.owns(id: id) }
    }

    private static var activeCenter: YTToastCenter? {
        hosts
            .compactMap { host -> (center: YTToastCenter, order: Int)? in
                guard let center = host.center else {
                    return nil
                }
                return (center, host.lastActive)
            }
            .max { $0.order < $1.order }?
            .center
    }

    private static func makeOrder() -> Int {
        defer { nextActiveOrder += 1 }
        return nextActiveOrder
    }
}
