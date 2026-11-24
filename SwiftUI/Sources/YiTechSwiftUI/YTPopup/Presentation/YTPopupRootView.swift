//
//  YTPopupRootView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Renders the popup layers owned by one host.
internal struct YTPopupRootView: View {
    @ObservedObject var center: YTPopupCenter

    var body: some View {
        ZStack {
            if center.layers.isEmpty {
                Color.clear
                    .allowsHitTesting(false)
            } else {
                ForEach(center.layers) { layer in
                    YTPopupLayerView(
                        layer: layer,
                        isTop: layer.id == topID,
                        onScrimTap: {
                            center.requestDismiss(id: layer.id)
                        }
                    )
                    .zIndex(zIndex(for: layer.id))
                    .onAppear {
                        center.activate(id: layer.id)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The topmost presented layer. A layer that is still presenting does not take
    /// the scrim or hit testing from the layer underneath until its content appears.
    private var topID: UUID? {
        center.layers.last { $0.state == .presented }?.id
    }

    private func zIndex(for id: UUID) -> Double {
        guard let index = center.layers.firstIndex(where: { $0.id == id }) else {
            return 0
        }
        return Double(index)
    }
}
