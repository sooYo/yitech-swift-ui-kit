//
//  YTPopupLayerView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// A single popup layer: scrim, aligned content, and insertion/removal transitions.
internal struct YTPopupLayerView: View {
    let layer: YTPopupLayer
    let isTop: Bool
    let onScrimTap: () -> Void

    var body: some View {
        ZStack(alignment: alignment) {
            if layer.state == .presented {
                scrim
                    .transition(.opacity)

                layer.content
                    .padding(contentPadding)
                    .transition(contentTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(isTop && layer.state == .presented)
    }

    private var entry: YTPopupOptions.Entry {
        layer.request.options.entry
    }

    private var alignment: Alignment {
        switch entry {
        case .automatic:
            return layer.request.kind == .sheet ? .bottom : .center
        case .bottom:
            return .bottom
        case .top:
            return .top
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .scale, .fade:
            return .center
        }
    }

    private var contentPadding: EdgeInsets {
        switch layer.request.kind {
        case .alert:
            EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        case .sheet:
            EdgeInsets()
        }
    }

    private var contentTransition: AnyTransition {
        switch entry {
        case .automatic:
            switch layer.request.kind {
            case .alert:
                return alertTransition
            case .sheet:
                return .move(edge: .bottom)
            }
        case .bottom:
            return .move(edge: .bottom)
        case .top:
            return .move(edge: .top)
        case .leading:
            return .move(edge: .leading)
        case .trailing:
            return .move(edge: .trailing)
        case .scale:
            return .scale(scale: 0.96).combined(with: .opacity)
        case .fade:
            return .opacity
        }
    }

    /// Alert entrance: a small offset plus a gentle squash/stretch settle, so
    /// the panel feels like soft jelly instead of a stiff scale. The exit stays
    /// the original scale/fade.
    private var alertTransition: AnyTransition {
        .asymmetric(
            insertion: .offset(x: 0, y: 4)
                .combined(with: .opacity)
                .combined(with: .modifier(
                    active: YTAlertEnterJelly(progress: 0),
                    identity: YTAlertEnterJelly(progress: 1)
                )),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        )
    }

    private var scrim: some View {
        (layer.request.options.scrimColor ?? defaultScrimColor)
            .ignoresSafeArea()
            .opacity(isTop ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isTop)
            .contentShape(Rectangle())
            .onTapGesture {
                guard layer.request.options.dismissible else {
                    return
                }

                onScrimTap()
            }
    }

    private var defaultScrimColor: Color {
        switch layer.request.kind {
        case .alert:
            .black.opacity(0.45)
        case .sheet:
            .black.opacity(0.34)
        }
    }
}

/// A small squash/stretch used while an alert enters.
private struct YTAlertEnterJelly: GeometryEffect {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let remaining = 1 - progress
        let amount = 0.018 * remaining
        let scaleX = 1 + amount
        let scaleY = 1 - amount
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        var transform = CGAffineTransform(translationX: center.x, y: center.y)
        transform = transform.scaledBy(x: scaleX, y: scaleY)
        transform = transform.translatedBy(x: -center.x, y: -center.y)

        return ProjectionTransform(transform)
    }
}
