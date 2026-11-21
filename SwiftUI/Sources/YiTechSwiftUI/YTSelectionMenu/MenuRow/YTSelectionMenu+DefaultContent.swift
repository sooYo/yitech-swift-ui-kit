//
//  YTSelectionMenu+DefaultContent.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Default row content for menus with custom capsule content or triggers
public extension YTSelectionMenu where RowContent == AnyView {
    init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder capsule: @escaping (String) -> Capsule
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
            style: style,
            label: label,
            capsule: capsule,
            rowContent: { item, _ in defaultRow(label(item)) }
        )
    }

    init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder trigger: @escaping (YTSelectionMenuTriggerContext) -> Capsule
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
            style: style,
            label: label,
            trigger: trigger,
            rowContent: { item, _ in defaultRow(label(item)) }
        )
    }
}

/// Default capsule content for menus with custom rows
public extension YTSelectionMenu where Capsule == AnyView {
    init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
            style: style,
            label: label,
            capsule: { defaultCapsule($0) },
            rowContent: rowContent
        )
    }
}

/// Default capsule and row content
public extension YTSelectionMenu where Capsule == AnyView, RowContent == AnyView {
    init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
            style: style,
            label: label,
            capsule: { defaultCapsule($0) },
            rowContent: { item, _ in defaultRow(label(item)) }
        )
    }
}

private func defaultCapsule(_ title: String) -> AnyView {
    AnyView(
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 16)
    )
}

private func defaultRow(_ title: String) -> AnyView {
    AnyView(
        Text(title)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.leading, 10)
            .frame(width: 156, height: 34, alignment: .leading)
    )
}
