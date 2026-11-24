//
//  YTSheetButton.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// A footer button inside a sheet panel.
internal struct YTSheetButton: View {
    enum Style {
        case primary
        case secondary
    }

    let action: YTSheetAction
    let style: Style
    let appearance: YTSheetStyle

    var body: some View {
        Button(action: action.action) {
            Text(action.title)
                .font(.system(
                    size: appearance.buttonFontSize,
                    weight: style == .primary ? .semibold : .medium
                ))
                .foregroundStyle(
                    style == .primary
                        ? appearance.primaryForeground
                        : appearance.secondaryForeground
                )
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    style == .primary ? appearance.primarySurface : appearance.cardSurface,
                    in: RoundedRectangle(
                        cornerRadius: appearance.buttonCornerRadius,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(!action.isEnabled)
        .opacity(action.isEnabled ? 1 : 0.45)
    }
}
