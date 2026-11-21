//
//  YTSelectionMenu.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// A selection menu whose capsule grows into its panel around a fixed center
public struct YTSelectionMenu<Item: Identifiable & Hashable, Capsule: View, RowContent: View>: View {
    /// Custom capsule supplies content; the menu owns its button behavior and morphing background
    public init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        corner: Double = 20,
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder capsule: @escaping (String) -> Capsule,
        @ViewBuilder rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
            corner: corner,
            style: style,
            label: label,
            wrapsCapsuleInButton: true,
            capsuleContent: { capsule($0.title) },
            rowContent: rowContent
        )
    }

    /// Reuses an existing interactive view; call `context.open()` from its action
    public init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        corner: Double = 20,
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder trigger: @escaping (YTSelectionMenuTriggerContext) -> Capsule,
        @ViewBuilder rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
            corner: corner,
            style: style,
            label: label,
            wrapsCapsuleInButton: false,
            capsuleContent: trigger,
            rowContent: rowContent
        )
    }

    private init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String,
        corner: Double,
        style: YTSelectionMenuStyle,
        label: @escaping (Item) -> String,
        wrapsCapsuleInButton: Bool,
        capsuleContent: @escaping (YTSelectionMenuTriggerContext) -> Capsule,
        rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.items = items
        self._selection = selection
        self.placeholder = placeholder
        self.corner = corner
        self.style = style
        self.label = label
        self.wrapsCapsuleInButton = wrapsCapsuleInButton
        self.capsuleContent = capsuleContent
        self.rowContent = rowContent
    }

    private let items: [Item]
    @Binding private var selection: Item.ID?
    private let placeholder: String
    private let corner: Double
    private let style: YTSelectionMenuStyle
    private let label: (Item) -> String
    private let wrapsCapsuleInButton: Bool
    private let capsuleContent: (YTSelectionMenuTriggerContext) -> Capsule
    private let rowContent: (Item, Bool) -> RowContent

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isExpanded = false
    @State private var isPressed = false
    @State private var pressScale: Double = 1
    @State private var showsHighlighter = true
    @State private var pressTask: Task<Void, Never>?

    private var currentLabel: String {
        items.first(where: { $0.id == selection }).map(label) ?? placeholder
    }

    private var panelCorner: Double {
        min(40, max(0, style.panel.cornerRadius ?? corner))
    }

    private var shapeCorner: Double {
        isExpanded ? panelCorner : min(19, max(0, corner * 19 / 20))
    }

    private var shapeAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.16) : .spring(response: 0.22, dampingFraction: 1)
    }

    private var panelSize: CGSize {
        CGSize(
            width: style.dimensions.row.width + 24,
            height: style.dimensions.row.height * CGFloat(items.count) + CGFloat(max(0, items.count - 1)) * 2 + 24
        )
    }

    private var stageSize: CGSize {
        CGSize(
            width: max(style.dimensions.capsule.width, panelSize.width) + 40,
            height: max(style.dimensions.capsule.height, panelSize.height) + 40
        )
    }

    public var body: some View {
        ZStack {
            Color.clear
                .frame(width: stageSize.width, height: stageSize.height)
                .contentShape(Rectangle())
                .onTapGesture(perform: collapse)
                .allowsHitTesting(isExpanded)

            RoundedRectangle(cornerRadius: shapeCorner, style: .continuous)
                .fill(isExpanded ? style.panel.backgroundColor : style.capsuleBackgroundColor)
                .frame(
                    width: isExpanded ? panelSize.width : style.dimensions.capsule.width,
                    height: isExpanded ? panelSize.height : style.dimensions.capsule.height
                )
                .shadow(
                    color: isExpanded ? style.panel.shadow?.color ?? .clear : .clear,
                    radius: isExpanded ? style.panel.shadow?.radius ?? 0 : 0,
                    x: isExpanded ? style.panel.shadow?.x ?? 0 : 0,
                    y: isExpanded ? style.panel.shadow?.y ?? 0 : 0
                )
                .scaleEffect(pressScale)
                .onTapGesture {}

            capsule
                .opacity(isExpanded ? 0 : 1)
                .allowsHitTesting(!isExpanded)
                .animation(.easeOut(duration: 0.16), value: isExpanded)

            rows
                .allowsHitTesting(isExpanded)
                .accessibilityHidden(!isExpanded)
        }
        .frame(width: stageSize.width, height: stageSize.height)
        .onChangeCompatible(of: isPressed, perform: handlePressChange)
        .onDisappear { pressTask?.cancel() }
    }

    @ViewBuilder
    private var capsule: some View {
        if wrapsCapsuleInButton {
            Button(action: expand) { capsuleVisual }
                .buttonStyle(YTSelectionMenuPressStyle(isPressed: $isPressed))
                .disabled(items.isEmpty)
                .accessibilityLabel(currentLabel)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        } else {
            capsuleVisual
                .disabled(items.isEmpty)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        }
    }

    private var capsuleVisual: some View {
        capsuleContent(.init(title: currentLabel, isExpanded: isExpanded, open: expand))
            .frame(width: style.dimensions.capsule.width, height: style.dimensions.capsule.height)
            .clipped()
            .contentShape(Rectangle())
            .scaleEffect(pressScale)
    }

    private var rows: some View {
        VStack(spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                YTSelectionMenuRow(
                    title: label(item),
                    isSelected: selection == item.id,
                    showsHighlighter: style.highlighter.isVisible && showsHighlighter,
                    highlighter: style.highlighter,
                    size: style.dimensions.row,
                    corner: min(17, max(0, corner - 10)),
                    action: { select(item) },
                    content: { rowContent(item, selection == item.id) }
                )
                .opacity(isExpanded ? 1 : 0)
                .animation(
                    .easeOut(duration: 0.16)
                        .delay(isExpanded && !reduceMotion ? 0.03 + Double(index) * 0.022 : 0),
                    value: isExpanded
                )
                .offset(y: reduceMotion || isExpanded ? 0 : 6)
                .animation(
                    reduceMotion
                        ? .easeOut(duration: 0.16)
                        : .timingCurve(0.22, 1, 0.36, 1, duration: 0.22)
                        .delay(isExpanded ? 0.03 + Double(index) * 0.022 : 0),
                    value: isExpanded
                )
            }
        }
        .padding(12)
        .frame(width: panelSize.width, height: panelSize.height)
    }

    private func handlePressChange(_ pressed: Bool) {
        pressTask?.cancel()

        guard pressed, !isExpanded else {
            if !isExpanded {
                withAnimation(.easeOut(duration: 0.22)) { pressScale = 1 }
            }
            return
        }

        guard !reduceMotion else {
            return
        }

        withAnimation(.easeOut(duration: 0.16)) { pressScale = 0.94 }
        pressTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(60))
            guard !Task.isCancelled, isPressed else {
                return
            }

            expand()
        }
    }

    private func expand() {
        guard !items.isEmpty, !isExpanded else {
            return
        }

        showsHighlighter = true
        withAnimation(shapeAnimation) { isExpanded = true }
        withAnimation(.easeOut(duration: 0.22)) { pressScale = 1 }
        isPressed = false
    }

    private func collapse() {
        guard isExpanded else {
            return
        }

        withAnimation(shapeAnimation) { isExpanded = false }
    }

    private func select(_ item: Item) {
        showsHighlighter = false
        selection = item.id
        collapse()
    }
}

private struct YTSelectionMenuPressStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChangeCompatible(of: configuration.isPressed) { isPressed = $0 }
    }
}

#if DEBUG

private struct YTSelectionMenuPreviewItem: Identifiable, Hashable {
    let id: String
    let name: String
}

/// Interactive preview for the default menu content
private struct YTSelectionMenuPreview: View {
    @State private var selection: String?
    private let style: YTSelectionMenuStyle

    private let items = [
        YTSelectionMenuPreviewItem(id: "all", name: "全部"),
        YTSelectionMenuPreviewItem(id: "warm", name: "暖色调"),
        YTSelectionMenuPreviewItem(id: "cool", name: "冷色调"),
        YTSelectionMenuPreviewItem(id: "neutral", name: "中性色")
    ]

    init(selection: String? = nil, style: YTSelectionMenuStyle = .init()) {
        _selection = State(initialValue: selection)
        self.style = style
    }

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            placeholder: "选择颜色",
            style: style
        ) { $0.name }
    }
}

#Preview("未选择") {
    YTSelectionMenuPreview()
}

#Preview("关闭高亮") {
    YTSelectionMenuPreview(
        selection: "warm",
        style: .init(highlighter: .init(isVisible: false))
    )
}

private struct YTSelectionMenuCustomCapsule: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "paintpalette")
            Text(title)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 18)
        .frame(height: 38)
        .frame(minWidth: 120)
        .background(Color(red: 0.92, green: 0.95, blue: 0.93))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

private struct YTSelectionMenuCustomPreview: View {
    @State private var selection: String?

    private let items = [
        YTSelectionMenuPreviewItem(id: "all", name: "全部"),
        YTSelectionMenuPreviewItem(id: "warm", name: "暖色调"),
        YTSelectionMenuPreviewItem(id: "cool", name: "冷色调")
    ]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            placeholder: "选择颜色",
            style: .init(
                panel: .init(
                    backgroundColor: Color(red: 0.92, green: 0.95, blue: 0.93),
                    cornerRadius: 24,
                    shadow: .init(radius: 16, y: 8)
                ),
                dimensions: .init(
                    capsule: .init(160, 38),
                    row: .init(236, 44)
                ),
                highlighter: .init(
                    icon: Image(systemName: "circle.inset.filled"),
                    backgroundColor: .black.opacity(0.08)
                ),
                capsuleBackgroundColor: .white
            ),
            label: { $0.name },
            capsule: { YTSelectionMenuCustomCapsule(title: $0) },
            rowContent: { item, isSelected in
                HStack(spacing: 8) {
                    Image(systemName: "paintpalette")
                    Text(item.name)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
                .foregroundStyle(.black)
                .padding(.leading, 12)
                .frame(width: 204, height: 44, alignment: .leading)
            }
        )
    }
}

#Preview("自定义 Capsule") {
    YTSelectionMenuCustomPreview()
}

private struct YTSelectionMenuExistingButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "slider.horizontal.3")
                .padding(.horizontal, 18)
                .frame(height: 38)
        }
        .buttonStyle(.plain)
    }
}

private struct YTSelectionMenuTriggerPreview: View {
    @State private var selection: String?

    private let items = [
        YTSelectionMenuPreviewItem(id: "all", name: "全部"),
        YTSelectionMenuPreviewItem(id: "warm", name: "暖色调"),
        YTSelectionMenuPreviewItem(id: "cool", name: "冷色调")
    ]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            placeholder: "选择颜色",
            style: .init(dimensions: .init(capsule: .init(180, 38))),
            label: { $0.name },
            trigger: { context in
                YTSelectionMenuExistingButton(title: context.title, action: context.open)
            }
        )
    }
}

#Preview("已有按钮触发") {
    YTSelectionMenuTriggerPreview()
}

private struct YTSelectionMenuExpandedPreview: View {
    @State private var selection: String? = "warm"

    private let items = [
        YTSelectionMenuPreviewItem(id: "all", name: "全部"),
        YTSelectionMenuPreviewItem(id: "warm", name: "暖色调"),
        YTSelectionMenuPreviewItem(id: "cool", name: "冷色调")
    ]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            style: .init(
                panel: .init(shadow: .init()),
                dimensions: .init(capsule: .init(180, 38)),
                highlighter: .init(icon: Image(systemName: "star.fill"))
            ),
            label: { $0.name },
            trigger: { context in
                YTSelectionMenuExistingButton(title: context.title, action: context.open)
                    .onAppear { context.open() }
            }
        )
    }
}

#Preview("展开 · 亮色") {
    YTSelectionMenuExpandedPreview()
        .preferredColorScheme(.light)
}

#Preview("展开 · 深色") {
    YTSelectionMenuExpandedPreview()
        .preferredColorScheme(.dark)
}

#endif
