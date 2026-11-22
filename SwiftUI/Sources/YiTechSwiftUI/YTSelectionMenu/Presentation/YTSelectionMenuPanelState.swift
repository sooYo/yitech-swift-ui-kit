//
//  YTSelectionMenuPanelState.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-22.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Live state of one expanded panel, shared by the menu and the layer that draws it
///
/// Mutable by design, but only the main actor reads or writes it: the menu mutates it from its
/// gestures and the floating layer observes it while the panel is on screen.
final class YTSelectionMenuPanelState: ObservableObject, @unchecked Sendable {
    /// Capsule rect in window space; the shape stays centered on it and follows it while scrolling
    @Published var anchor: CGRect

    /// Drives the shape morph and the per-row appearance, exactly like the in-place panel
    @Published var isExpanded: Bool

    let spec: YTSelectionMenuPanelSpec

    /// Builds the rows for the given expansion state; the layer only positions them
    let rows: (Bool) -> AnyView

    /// Forwarded from the layer's dismiss area
    let onDismissRequest: () -> Void

    /// Called once the layer has rendered, so the shape morphs instead of appearing expanded
    var onAppear: (() -> Void)?

    init(
        anchor: CGRect,
        isExpanded: Bool,
        spec: YTSelectionMenuPanelSpec,
        rows: @escaping (Bool) -> AnyView,
        onDismissRequest: @escaping () -> Void
    ) {
        self.anchor = anchor
        self.isExpanded = isExpanded
        self.spec = spec
        self.rows = rows
        self.onDismissRequest = onDismissRequest
    }
}

// MARK: - Hosting

/// Draws an expanded panel outside the trigger's view hierarchy
protocol YTSelectionMenuPanelPresenting: AnyObject {
    /// Returns false when nothing can host the panel; the menu then draws it in place
    func present(_ state: YTSelectionMenuPanelState) -> Bool

    func dismiss(_ state: YTSelectionMenuPanelState)
}

enum YTSelectionMenuPanelPresenters {
    /// Replaced by tests; production code only touches it from the main thread
    nonisolated(unsafe) static var shared: any YTSelectionMenuPanelPresenting = {
        #if os(iOS) || os(tvOS)
        YTSelectionMenuFloatingPresenter()
        #else
        YTSelectionMenuInPlacePresenter()
        #endif
    }()
}

/// Used where no layer can host the panel; drawing in place is the only option
final class YTSelectionMenuInPlacePresenter: YTSelectionMenuPanelPresenting {
    func present(_ state: YTSelectionMenuPanelState) -> Bool {
        false
    }

    func dismiss(_ state: YTSelectionMenuPanelState) {}
}
