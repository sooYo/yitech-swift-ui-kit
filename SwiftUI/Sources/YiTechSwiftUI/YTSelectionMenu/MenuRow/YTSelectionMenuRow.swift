//
//  YTSelectionMenuRow.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// A selectable row in the expanded menu
struct YTSelectionMenuRow<Content: View>: View {
    let title: String
    let isSelected: Bool
    let showsHighlighter: Bool
    let highlighter: YTSelectionMenuStyle.Highlighter
    let size: YTSelectionMenuStyle.Dimensions.Size
    let cornerRadius: CGFloat
    let action: () -> Void
    let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(
                    width: max(0, size.width - (highlighter.isVisible ? 32 : 0)),
                    height: size.height,
                    alignment: .leading
                )
                .clipped()
                .frame(width: size.width, height: size.height, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isSelected && showsHighlighter ? highlighter.backgroundColor : .clear)
                        .transaction { $0.animation = nil }
                }
                .overlay(alignment: .trailing) {
                    highlighter.icon
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                        .frame(width: 12, height: 12)
                        .frame(width: 22, height: 22)
                        .background(.regularMaterial, in: Circle())
                        .opacity(isSelected && showsHighlighter ? 1 : 0)
                        .padding(.trailing, 10)
                        .transaction { $0.animation = nil }
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

