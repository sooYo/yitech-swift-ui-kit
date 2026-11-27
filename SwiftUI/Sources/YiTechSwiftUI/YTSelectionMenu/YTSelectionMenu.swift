//
//  YTSelectionMenu.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// A selection menu whose panel floats around the trigger without changing its layout size
public struct YTSelectionMenu<Item: Identifiable & Hashable, Capsule: View, RowContent: View>: View {
    /// Custom capsule supplies content; the menu owns its button behavior and morphing background
    public init(
        items: [Item],
        selection: Binding<Item.ID?>,
        placeholder: String = "Select",
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder capsule: @escaping (String) -> Capsule,
        @ViewBuilder rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
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
        style: YTSelectionMenuStyle = .init(),
        label: @escaping (Item) -> String,
        @ViewBuilder trigger: @escaping (YTSelectionMenuTriggerContext) -> Capsule,
        @ViewBuilder rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.init(
            items: items,
            selection: selection,
            placeholder: placeholder,
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
        style: YTSelectionMenuStyle,
        label: @escaping (Item) -> String,
        wrapsCapsuleInButton: Bool,
        capsuleContent: @escaping (YTSelectionMenuTriggerContext) -> Capsule,
        rowContent: @escaping (Item, Bool) -> RowContent
    ) {
        self.items = items
        self._selection = selection
        self.placeholder = placeholder
        self.style = style
        self.label = label
        self.wrapsCapsuleInButton = wrapsCapsuleInButton
        self.capsuleContent = capsuleContent
        self.rowContent = rowContent
    }

    private let items: [Item]
    @Binding private var selection: Item.ID?
    private let placeholder: String
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
    @State private var floatingState: YTSelectionMenuPanelState?
    @State private var presentationTask: Task<Void, Never>?
    @State private var presentsInline = true
    @State private var capsuleFrame = CGRect.zero

    private var currentLabel: String {
        items.first(where: { $0.id == selection }).map(label) ?? placeholder
    }

    private var shapeCornerRadius: Double {
        max(0, isExpanded ? style.panel.cornerRadius : style.capsuleCornerRadius)
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

    public var body: some View {
        capsule
            .opacity(isExpanded ? 0 : 1)
            .animation(.easeOut(duration: 0.16), value: isExpanded)
            .background {
                GeometryReader { geometry in
                    shape(in: geometry.size)
                }
            }
            .background {
                capsuleFrameProbe
            }
            .overlay {
                if presentsInline {
                    inlinePanel
                }
            }
        .zIndex(isExpanded ? 1 : 0)
        .onChangeCompatible(of: isPressed, perform: handlePressChange)
        .onDisappear(perform: handleDisappear)
    }

    @ViewBuilder
    private var capsule: some View {
        if wrapsCapsuleInButton {
            Button(action: expand) { capsuleVisual }
                .buttonStyle(YTSelectionMenuPressStyle(isPressed: $isPressed))
                .disabled(items.isEmpty)
                .allowsHitTesting(!isExpanded)
                .accessibilityLabel(currentLabel)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        } else {
            capsuleVisual
                .disabled(items.isEmpty)
                .allowsHitTesting(!isExpanded)
                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        }
    }

    @ViewBuilder
    private var capsuleVisual: some View {
        if wrapsCapsuleInButton {
            capsuleContent(.init(title: currentLabel, isExpanded: isExpanded, open: expand))
                .frame(width: style.dimensions.capsule.width, height: style.dimensions.capsule.height)
                .clipped()
                .contentShape(Rectangle())
                .scaleEffect(pressScale)
        } else {
            capsuleContent(.init(title: currentLabel, isExpanded: isExpanded, open: expand))
        }
    }

    /// The morphing background; the floating layer draws the expanded version of this same shape
    private func shape(in size: CGSize) -> some View {
        let expandsInPlace = isExpanded && presentsInline

        return RoundedRectangle(cornerRadius: shapeCornerRadius, style: .continuous)
            .fill(expandsInPlace ? style.panel.backgroundColor : style.capsuleBackgroundColor)
            .frame(
                width: expandsInPlace ? panelSize.width : size.width,
                height: expandsInPlace ? panelSize.height : size.height
            )
            .shadow(
                color: expandsInPlace ? style.panel.shadow?.color ?? .clear : .clear,
                radius: expandsInPlace ? style.panel.shadow?.radius ?? 0 : 0,
                x: expandsInPlace ? style.panel.shadow?.x ?? 0 : 0,
                y: expandsInPlace ? style.panel.shadow?.y ?? 0 : 0
            )
            .scaleEffect(pressScale)
            .position(x: size.width / 2, y: size.height / 2)
            .opacity(floatingState == nil ? 1 : 0)
    }

    /// Reports the capsule rect in window space, the origin the floating layer morphs from
    private var capsuleFrameProbe: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)

            Color.clear
                .onAppear { updateCapsuleFrame(frame) }
                .onChangeCompatible(of: frame) { newFrame in
                    updateCapsuleFrame(newFrame)
                }
        }
    }

    private func updateCapsuleFrame(_ frame: CGRect) {
        capsuleFrame = frame

        // Keep the presented panel anchored to the trigger, so scrolling moves it along
        floatingState?.anchor = frame
    }

    /// Rows and dismiss area drawn inside the trigger, used when no layer can host the panel
    @ViewBuilder
    private var inlinePanel: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                    .frame(
                        width: max(geometry.size.width, panelSize.width) + 40,
                        height: max(geometry.size.height, panelSize.height) + 40
                    )
                    .contentShape(Rectangle())
                    .onTapGesture(perform: collapse)
                    .allowsHitTesting(isExpanded)

                rowsContent(isExpanded: isExpanded, showsHighlighter: showsHighlighter)
                    .allowsHitTesting(isExpanded)
                    .accessibilityHidden(!isExpanded)
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private func rowsContent(isExpanded: Bool, showsHighlighter: Bool) -> some View {
        VStack(spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                YTSelectionMenuRow(
                    title: label(item),
                    isSelected: selection == item.id,
                    showsHighlighter: style.highlighter.isVisible && showsHighlighter,
                    highlighter: style.highlighter,
                    size: style.dimensions.row,
                    cornerRadius: max(0, style.rowCornerRadius),
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
        withAnimation(.easeOut(duration: 0.22)) { pressScale = 1 }
        isPressed = false

        presentationTask?.cancel()
        presentationTask = Task { @MainActor in
            // The probe reports the capsule rect during layout; one hop is enough to have it
            await Task.yield()

            guard capsuleFrame.width > 0, capsuleFrame.height > 0 else {
                presentInPlace()
                return
            }

            let state = makePanelState()

            guard YTSelectionMenuPanelPresenters.shared.present(state) else {
                presentInPlace()
                return
            }

            presentsInline = false
            floatingState = state

            withAnimation(.easeOut(duration: 0.16)) { isExpanded = true }
        }
    }

    /// Falls back to the in-place panel, which is the only option below the trigger's own layer
    private func presentInPlace() {
        presentsInline = true
        withAnimation(shapeAnimation) { isExpanded = true }
    }

    private func collapse() {
        guard isExpanded else {
            return
        }

        presentationTask?.cancel()

        guard let state = floatingState else {
            withAnimation(shapeAnimation) { isExpanded = false }
            return
        }

        withAnimation(shapeAnimation) {
            state.isExpanded = false
            isExpanded = false
        }

        presentationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 200 : 320))

            guard !Task.isCancelled else {
                return
            }

            tearDownFloating()
        }
    }

    private func tearDownFloating() {
        guard let state = floatingState else {
            presentsInline = true
            return
        }

        YTSelectionMenuPanelPresenters.shared.dismiss(state)
        floatingState = nil
        presentsInline = true
    }

    private func handleDisappear() {
        pressTask?.cancel()
        presentationTask?.cancel()
        tearDownFloating()
    }

    private func makePanelState() -> YTSelectionMenuPanelState {
        let spec = YTSelectionMenuPanelSpec(
            capsuleSize: capsuleFrame.size,
            panelSize: panelSize,
            capsuleCornerRadius: style.capsuleCornerRadius,
            panelCornerRadius: style.panel.cornerRadius,
            capsuleColor: style.capsuleBackgroundColor,
            panelColor: style.panel.backgroundColor,
            shadow: style.panel.shadow
        )

        let state = YTSelectionMenuPanelState(
            anchor: capsuleFrame,
            isExpanded: false,
            spec: spec,
            rows: { expanded, showsHighlighter in
                AnyView(self.rowsContent(isExpanded: expanded, showsHighlighter: showsHighlighter))
            },
            onDismissRequest: {
                self.collapse()
            }
        )
        let animation = shapeAnimation

        // The layer grows on its own first frame, so the shape morphs out of the capsule rect
        state.onAppear = {
            withAnimation(animation) { state.isExpanded = true }
        }

        return state
    }

    private func select(_ item: Item) {
        showsHighlighter = false
        floatingState?.showsHighlighter = false
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
        YTSelectionMenuPreviewItem(id: "all", name: "All"),
        YTSelectionMenuPreviewItem(id: "warm", name: "Warm tones"),
        YTSelectionMenuPreviewItem(id: "cool", name: "Cool tones"),
        YTSelectionMenuPreviewItem(id: "neutral", name: "Neutrals")
    ]

    init(selection: String? = nil, style: YTSelectionMenuStyle = .init()) {
        _selection = State(initialValue: selection)
        self.style = style
    }

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            placeholder: "Select a color",
            style: style
        ) { $0.name }
    }
}

#Preview("Unselected") {
    YTSelectionMenuPreview()
}

#Preview("Highlight Hidden") {
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
        YTSelectionMenuPreviewItem(id: "all", name: "All"),
        YTSelectionMenuPreviewItem(id: "warm", name: "Warm tones"),
        YTSelectionMenuPreviewItem(id: "cool", name: "Cool tones")
    ]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            placeholder: "Select a color",
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

#Preview("Custom Capsule") {
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
    @State private var selection: String? = "hsb"

    let opensOnAppear: Bool

    private let items = [
        YTSelectionMenuPreviewItem(id: "hex", name: "HEX"),
        YTSelectionMenuPreviewItem(id: "rgb", name: "RGB"),
        YTSelectionMenuPreviewItem(id: "hsl", name: "HSL"),
        YTSelectionMenuPreviewItem(id: "hsb", name: "HSB")
    ]

    var body: some View {
        VStack(spacing: 0) {
            settingsRow(symbol: "waveform", title: "Haptic Feedback", detail: "Provide haptic feedback on tap", value: "On")
            Divider().padding(.leading, 60)
            settingsRow(symbol: "textformat.abc", title: "Show Color Names and Values", detail: "Show color details when space allows", value: "On")
            Divider().padding(.leading, 60)

            YTSelectionMenu(
                items: items,
                selection: $selection,
                style: .init(
                    panel: .init(shadow: .init()),
                    dimensions: .init(row: .init(268, 40)),
                    capsuleBackgroundColor: .clear
                ),
                label: { $0.name },
                trigger: { context in
                    Button(action: context.open) {
                        settingsRow(
                            symbol: "number",
                            title: "Default Color Format",
                            detail: "Used for colors in your collection",
                            value: context.title
                        )
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if opensOnAppear { context.open() }
                    }
                }
            )

            Divider().padding(.leading, 60)
            settingsRow(symbol: "sparkles", title: "Similar Colors", detail: "Find colors related to your collection", value: "Coming Soon")
        }
        .frame(width: 320)
        .background(Color(red: 0.94, green: 0.94, blue: 0.93), in: RoundedRectangle(cornerRadius: 16))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func settingsRow(symbol: String, title: String, detail: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18))
                .foregroundStyle(Color(red: 0.35, green: 0.48, blue: 0.29))
                .frame(width: 32, height: 32)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
    }
}

#Preview("Settings Row · Collapsed") {
    YTSelectionMenuTriggerPreview(opensOnAppear: false)
}

#Preview("Settings Row · Expanded") {
    YTSelectionMenuTriggerPreview(opensOnAppear: true)
}

private struct YTSelectionMenuExpandedPreview: View {
    @State private var selection: String? = "warm"

    private let items = [
        YTSelectionMenuPreviewItem(id: "all", name: "All"),
        YTSelectionMenuPreviewItem(id: "warm", name: "Warm tones"),
        YTSelectionMenuPreviewItem(id: "cool", name: "Cool tones")
    ]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            style: .init(
                panel: .init(shadow: .init()),
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

#Preview("Expanded · Light") {
    YTSelectionMenuExpandedPreview()
        .preferredColorScheme(.light)
}

#Preview("Expanded · Dark") {
    YTSelectionMenuExpandedPreview()
        .preferredColorScheme(.dark)
}

#endif
