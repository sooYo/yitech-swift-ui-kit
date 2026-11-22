//
//  YTSelectionMenuFloatingPresenter.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-22.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

#if os(iOS) || os(tvOS)

import SwiftUI
import UIKit

/// Hosts the floating layer in the key window, so no neighbouring view can cover or intercept it
///
/// The menu reaches this presenter from expand, collapse and disappear paths that are not main
/// actor isolated, so the presenting requirements cannot be. Every UIKit touch is confined to the
/// helpers below instead, which assume main actor isolation from those entries.
///
/// The layer is main actor bound for the same reason: every entry point asserts the main thread
/// before touching it, so sending it across that boundary cannot introduce a data race.
final class YTSelectionMenuFloatingPresenter: YTSelectionMenuPanelPresenting, @unchecked Sendable {
    private var state: YTSelectionMenuPanelState?
    private var hostingController: UIHostingController<YTSelectionMenuFloatingLayer>?

    func present(_ state: YTSelectionMenuPanelState) -> Bool {
        guard Thread.isMainThread else {
            return false
        }

        return MainActor.assumeIsolated {
            presentOnMainActor(state)
        }
    }

    func dismiss(_ state: YTSelectionMenuPanelState) {
        guard Thread.isMainThread else {
            return
        }

        MainActor.assumeIsolated {
            dismissOnMainActor(state)
        }
    }
}

// MARK: - Main Actor Presentation

extension YTSelectionMenuFloatingPresenter {
    @MainActor
    private func presentOnMainActor(_ state: YTSelectionMenuPanelState) -> Bool {
        if self.state === state {
            return hostingController != nil
        }

        // The previous owner has to release its own state, or its trigger stays hidden
        self.state?.onDismissRequest()
        dismissAllOnMainActor()

        guard let window = Self.keyWindow() else {
            return false
        }

        let host = UIHostingController(rootView: YTSelectionMenuFloatingLayer(state: state))
        host.view.backgroundColor = .clear
        host.view.frame = window.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.accessibilityViewIsModal = true
        window.addSubview(host.view)

        self.state = state
        hostingController = host

        return true
    }

    @MainActor
    private func dismissOnMainActor(_ state: YTSelectionMenuPanelState) {
        guard self.state === state else {
            return
        }

        dismissAllOnMainActor()
    }

    @MainActor
    private func dismissAllOnMainActor() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        state = nil
    }

    @MainActor
    private static func keyWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }

        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }
}

#endif
