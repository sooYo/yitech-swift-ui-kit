//
//  YTCategoryView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-12.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Hierarchical category data displayed as a horizontally navigable picker.
public protocol YTCategoryItem: Identifiable where ID: Hashable {
    var name: String { get }
    var children: [Self] { get }
}

/// Shows one level of categories at a time and keeps the selected item synchronized with an optional binding.
public struct YTCategoryView<Item: YTCategoryItem>: View {
    /// Visual configuration shared by category chips and path buttons.
    public struct Style {
        public var height: CGFloat
        public var itemSpacing: CGFloat
        public var pathSpacing: CGFloat
        public var horizontalPadding: CGFloat
        public var selectedColor: Color
        public var unselectedColor: Color
        public var selectedTextColor: Color
        public var textColor: Color
        public var font: Font

        public init(
            height: CGFloat = 28,
            itemSpacing: CGFloat = 8,
            pathSpacing: CGFloat = 4,
            horizontalPadding: CGFloat = 16,
            selectedColor: Color = .primary,
            unselectedColor: Color = .secondary.opacity(0.12),
            selectedTextColor: Color = .white,
            textColor: Color = .primary,
            font: Font = .system(size: 12, weight: .medium)
        ) {
            self.height = height
            self.itemSpacing = itemSpacing
            self.pathSpacing = pathSpacing
            self.horizontalPadding = horizontalPadding
            self.selectedColor = selectedColor
            self.unselectedColor = unselectedColor
            self.selectedTextColor = selectedTextColor
            self.textColor = textColor
            self.font = font
        }
    }

    /// Creates a picker with the default chip appearance.
    public init(
        items: [Item],
        selectedID: Binding<Item.ID?>? = nil,
        initialSelectedID: Item.ID? = nil,
        style: Style = Style(),
        backgroundColor: Color = .clear,
        onSelect: ((Item) -> Void)? = nil
    ) {
        self.items = items
        self.selection = selectedID
        self.initialSelectedID = selectedID?.wrappedValue ?? initialSelectedID
        self.style = style
        self.backgroundColor = backgroundColor
        self.onSelect = onSelect
        self.itemBuilder = nil
        _internalSelectedID = State(initialValue: selectedID?.wrappedValue ?? initialSelectedID)
    }

    /// Creates a picker with custom content for each category chip.
    public init<Content: View>(
        items: [Item],
        selectedID: Binding<Item.ID?>? = nil,
        initialSelectedID: Item.ID? = nil,
        style: Style = Style(),
        backgroundColor: Color = .clear,
        onSelect: ((Item) -> Void)? = nil,
        @ViewBuilder itemBuilder: @escaping (Item, Bool, Bool) -> Content
    ) {
        self.items = items
        self.selection = selectedID
        self.initialSelectedID = selectedID?.wrappedValue ?? initialSelectedID
        self.style = style
        self.backgroundColor = backgroundColor
        self.onSelect = onSelect
        self.itemBuilder = { item, isSelected, hasChildren in
            AnyView(itemBuilder(item, isSelected, hasChildren))
        }
        _internalSelectedID = State(initialValue: selectedID?.wrappedValue ?? initialSelectedID)
    }

    private let items: [Item]
    private let selection: Binding<Item.ID?>?
    private let initialSelectedID: Item.ID?
    private let style: Style
    private let backgroundColor: Color
    private let onSelect: ((Item) -> Void)?
    private let itemBuilder: ((Item, Bool, Bool) -> AnyView)?

    @State private var internalSelectedID: Item.ID?
    @State private var path: [Item] = []
    @State private var isReturning = false
    @State private var isTransitioning = false
    @State private var lastPickerSelection: Item.ID?
    @State private var hasPendingPickerSelection = false
    @Namespace private var namespace

    private var selectedID: Item.ID? {
        selection.map { $0.wrappedValue } ?? internalSelectedID
    }

    private var visibleItems: [Item] {
        path.last?.children ?? items
    }

    public var body: some View {
        HStack(alignment: .center, spacing: style.pathSpacing) {
            ForEach(Array(path.enumerated()), id: \.element.id) { index, item in
                YTCategoryPathButton(
                    item: item,
                    isCurrent: index == path.count - 1,
                    isSelected: selectedID == item.id,
                    namespace: namespace,
                    style: style,
                    action: { navigate(to: index) }
                )
            }

            YTCategoryLevelPage(
                items: visibleItems,
                selectedID: selectedID,
                namespace: namespace,
                isReturning: isReturning,
                style: style,
                itemBuilder: itemBuilder,
                onSelect: select
            )
            .frame(maxWidth: .infinity)
            .frame(height: style.height + 4)
            .clipped()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: style.height + 4)
        .padding(.horizontal, style.horizontalPadding)
        .background(backgroundColor)
        .onAppear { synchronizePath(to: selectedID) }
        .onChange(of: selection?.wrappedValue) { newValue in
            if hasPendingPickerSelection {
                hasPendingPickerSelection = false
                
                if newValue == lastPickerSelection {
                    return
                }
            }
            
            synchronizePath(to: newValue)
        }
        .onChange(of: items.map(\.id)) { _ in synchronizePath(to: selectedID) }
    }

    private func select(_ item: Item) {
        if !item.children.isEmpty {
            guard !isTransitioning else {
                return
            }
            
            lockInteraction()
        }
        
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            setSelection(item.id)
            
            if !item.children.isEmpty {
                isReturning = false
                path.append(item)
            }
        }
        
        onSelect?(item)
    }

    private func navigate(to index: Int) {
        guard !isTransitioning, path.indices.contains(index) else {
            return
        }
        
        let item = path[index]
        lockInteraction()
        
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            isReturning = true
            path.removeSubrange(index ..< path.count)
            setSelection(item.id)
        }
        
        onSelect?(item)
    }

    private func lockInteraction() {
        isTransitioning = true
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            isTransitioning = false
        }
    }

    private func setSelection(_ id: Item.ID?) {
        internalSelectedID = id
        lastPickerSelection = id
        hasPendingPickerSelection = selection != nil
        selection?.wrappedValue = id
    }

    private func synchronizePath(to id: Item.ID?) {
        guard let id, let selectedPath = findPath(to: id, in: items) else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                path = []
                isReturning = true
            }
            
            return
        }
        
        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            path = Array(selectedPath.dropLast())
            isReturning = true
        }
    }

    private func findPath(to id: Item.ID, in items: [Item], ancestors: [Item] = []) -> [Item]? {
        for item in items {
            let candidatePath = ancestors + [item]
            if item.id == id {
                return candidatePath
            }
            
            if let nestedPath = findPath(to: id, in: item.children, ancestors: candidatePath) {
                return nestedPath
            }
        }
        
        return nil
    }
}

private struct YTCategoryPathButton<Item: YTCategoryItem>: View {
    let item: Item
    let isCurrent: Bool
    let isSelected: Bool
    let namespace: Namespace.ID
    let style: YTCategoryView<Item>.Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(item.name)
                    .font(.system(size: 12, weight: isCurrent ? .semibold : .medium))
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "category-title-\(item.id)", in: namespace)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .transition(chevronTransition)
            }
            .foregroundStyle(style.selectedTextColor)
            .padding(.horizontal, 9)
            .frame(height: style.height)
            .background {
                if isSelected {
                    Capsule()
                        .fill(style.selectedColor)
                        .matchedGeometryEffect(id: "selected-category", in: namespace)
                } else {
                    Capsule().fill(style.selectedColor)
                }
            }
            .clipShape(Capsule())
            .transition(isSelected ? .identity : .opacity.combined(with: .scale(scale: 0.96, anchor: .leading)))
        }
        .buttonStyle(YTCategoryButtonStyle())
    }

    private var chevronTransition: AnyTransition {
        guard isSelected else {
            return .identity
        }
        
        return .scale(scale: 0.01, anchor: .leading).combined(with: .opacity)
    }
}

private struct YTCategoryLevelPage<Item: YTCategoryItem>: View {
    let items: [Item]
    let selectedID: Item.ID?
    let namespace: Namespace.ID
    let isReturning: Bool
    let style: YTCategoryView<Item>.Style
    let itemBuilder: ((Item, Bool, Bool) -> AnyView)?
    let onSelect: (Item) -> Void

    var body: some View {
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
            scrollView.scrollClipDisabled()
        } else {
            scrollView
        }
    }

    private var scrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: style.itemSpacing) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    YTCategoryChip(
                        item: item,
                        isSelected: selectedID == item.id,
                        namespace: namespace,
                        isReturning: isReturning,
                        index: index,
                        style: style,
                        itemBuilder: itemBuilder,
                        action: { onSelect(item) }
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct YTCategoryChip<Item: YTCategoryItem>: View {
    let item: Item
    let isSelected: Bool
    let namespace: Namespace.ID
    let isReturning: Bool
    let index: Int
    let style: YTCategoryView<Item>.Style
    let itemBuilder: ((Item, Bool, Bool) -> AnyView)?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if let itemBuilder {
                itemBuilder(item, isSelected, !item.children.isEmpty)
                    .frame(height: style.height)
            } else {
                Text(item.name)
                    .font(style.font)
                    .lineLimit(1)
                    .matchedGeometryEffect(id: "category-title-\(item.id)", in: namespace)
                    .foregroundStyle(isSelected ? style.selectedTextColor : style.textColor)
                    .padding(.horizontal, 10)
                    .frame(height: style.height)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(style.selectedColor)
                                .matchedGeometryEffect(id: "selected-category", in: namespace)
                        } else {
                            Capsule().fill(style.unselectedColor)
                        }
                    }
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(YTCategoryButtonStyle())
        .transition(categoryTransition)
        .accessibilityLabel(item.name)
    }

    private var categoryTransition: AnyTransition {
        let visibleIndex = min(index, 5)
        let insertion: AnyTransition
        if isReturning {
            insertion = isSelected
                ? .identity
                : .opacity.animation(.easeOut(duration: 0.12).delay(Double(visibleIndex) * 0.025))
        } else {
            insertion = .scale(scale: 0.92, anchor: .leading)
                .animation(.spring(response: 0.3, dampingFraction: 0.84))
        }
        
        let removal: AnyTransition = isSelected
            ? .identity
            : .opacity.animation(.easeOut(duration: 0.12))
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

private struct YTCategoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

private struct YTCategoryViewPreviewItem: YTCategoryItem {
    let id: String
    let name: String
    let children: [YTCategoryViewPreviewItem]
}

private struct YTCategoryViewPreview: View {
    @State private var selectedID: String? = "warm"

    private let items = [
        YTCategoryViewPreviewItem(
            id: "palette",
            name: "配色",
            children: [
                YTCategoryViewPreviewItem(
                    id: "warm",
                    name: "暖色",
                    children: [
                        YTCategoryViewPreviewItem(id: "coral", name: "珊瑚", children: []),
                        YTCategoryViewPreviewItem(id: "amber", name: "琥珀", children: [])
                    ]
                ),
                YTCategoryViewPreviewItem(id: "cool", name: "冷色", children: [])
            ]
        ),
        YTCategoryViewPreviewItem(id: "material", name: "材质", children: [])
    ]

    var body: some View {
        YTCategoryView(
            items: items,
            selectedID: $selectedID,
            style: .init(
                height: 28,
                itemSpacing: 8,
                pathSpacing: 4,
                horizontalPadding: 16,
                selectedColor: Color(red: 0.15, green: 0.16, blue: 0.18),
                unselectedColor: Color(red: 0.93, green: 0.93, blue: 0.94),
                selectedTextColor: .white,
                textColor: .primary
            )
        )
        .frame(width: 360, alignment: .leading)
        .padding(.vertical, 8)
        .background(.background)
    }
}

#Preview("Category picker") {
    YTCategoryViewPreview()
        .padding(.vertical, 24)
}
