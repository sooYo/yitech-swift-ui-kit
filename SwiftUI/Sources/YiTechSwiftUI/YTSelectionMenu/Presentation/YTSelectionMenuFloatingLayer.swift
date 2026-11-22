//
//  YTSelectionMenuFloatingLayer.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-22.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Draws the shared shape and its rows over the whole window, centered on the trigger
///
/// The layer reproduces the in-place visuals: the same shape grows from the capsule rect with the
/// same corner radius and fill, and the rows fade and slide in with their own delays. Drawing it
/// outside the trigger's subtree is what keeps it above the neighbouring cards and tappable.
struct YTSelectionMenuFloatingLayer: View {
    @ObservedObject var state: YTSelectionMenuPanelState

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: state.onDismissRequest)
                .allowsHitTesting(state.isExpanded)

            shape

            state.rows(state.isExpanded)
                .position(x: state.anchor.midX, y: state.anchor.midY)
                .allowsHitTesting(state.isExpanded)
                .accessibilityHidden(!state.isExpanded)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear { state.onAppear?() }
    }

    private var shape: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(state.isExpanded ? state.spec.panelColor : state.spec.capsuleColor)
            .frame(width: size.width, height: size.height)
            .shadow(
                color: state.isExpanded ? state.spec.shadow?.color ?? .clear : .clear,
                radius: state.isExpanded ? state.spec.shadow?.radius ?? 0 : 0,
                x: state.isExpanded ? state.spec.shadow?.x ?? 0 : 0,
                y: state.isExpanded ? state.spec.shadow?.y ?? 0 : 0
            )
            .position(x: state.anchor.midX, y: state.anchor.midY)
    }

    private var cornerRadius: Double {
        max(0, state.isExpanded ? state.spec.panelCornerRadius : state.spec.capsuleCornerRadius)
    }

    private var size: CGSize {
        state.isExpanded ? state.spec.panelSize : state.spec.capsuleSize
    }
}
