//  YTToastHostView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

internal struct YTToastHostView: View {
    @ObservedObject var center: YTToastCenter

    var body: some View {
        ZStack {
            if let request = center.current, !center.isDismissing {
                if request.style.configuration.interaction.blocksBackgroundInteraction {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {}
                        .accessibilityHidden(true)
                }

                request.style.makeBody(for: request.content)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: request))
                    .transition(transition(for: request))
                    .id(request.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(animation, value: center.current?.id)
        .animation(animation, value: center.isDismissing)
        .accessibilityElement(children: .contain)
    }

    private var animation: Animation {
        guard let request = center.current else {
            return .default
        }
        return center.isDismissing
            ? request.style.configuration.animation.dismiss.animation
            : request.style.configuration.animation.show.animation
    }

    private func transition(for request: YTToastRequest) -> AnyTransition {
        .asymmetric(
            insertion: request.style.configuration.animation.show.transition,
            removal: request.style.configuration.animation.dismiss.transition
        )
    }

    private func alignment(for request: YTToastRequest) -> Alignment {
        switch request.style.configuration.position {
        case .center:
            .center
        case .top:
            .top
        case .bottom:
            .bottom
        }
    }
}
