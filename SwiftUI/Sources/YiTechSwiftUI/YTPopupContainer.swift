//
//  YTPopupContainer.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/10/16.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

// MARK: - Data

public struct YTPopupTransition {
    public struct YTPopupEffect {
        public let transition: AnyTransition
        public let animation: Animation
    }

    public let insertion: YTPopupEffect
    public let removal: YTPopupEffect

    // MARK: - Transition Shortcuts

    /// Slide in from the `edge` with spring animation and out with easeIn animation by default
    public static func slide(
        from edge: Edge,
        in insertAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.85),
        out removalAnimation: Animation = .easeIn(duration: 0.2)
    ) -> Self {
        let transition = AnyTransition.move(edge: edge).combined(with: .opacity)
        return .init(
            insertion: .init(transition: transition, animation: insertAnimation),
            removal: .init(transition: transition, animation: removalAnimation)
        )
    }

    /// Slide in with spring animation and fade out with easeInt animation
    public static func slideInAndFadeOut(
        from edge: Edge,
        in insertAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.85),
        out removalAnimation: Animation = .easeIn(duration: 0.2)
    ) -> Self {
        .init(
            insertion: .init(
                transition: .move(edge: edge).combined(with: .opacity),
                animation: insertAnimation
            ),
            removal: .init(
                transition: .opacity,
                animation: removalAnimation
            )
        )
    }

    /// Zoom in/out with opacity
    public static func scale(
        inScale: Double = 0.85,
        outScale: Double = 0.65,
        in insertAnimation: Animation = .spring(response: 0.4, dampingFraction: 0.85),
        out removalAnimation: Animation = .easeIn(duration: 0.2)
    ) -> Self {
        .init(
            insertion: .init(
                transition: .scale(scale: inScale).combined(with: .opacity),
                animation: insertAnimation
            ),
            removal: .init(
                transition: .scale(scale: outScale).combined(with: .opacity),
                animation: removalAnimation
            )
        )
    }

    public static var fade: Self {
        .init(
            insertion: .init(transition: .opacity, animation: .easeOut(duration: 0.2)),
            removal: .init(transition: .opacity, animation: .easeIn(duration: 0.2))
        )
    }
}

public extension YTPopupTransition {
    static func slide(by alignment: Alignment) -> Self {
        switch alignment {
        case .leading:
            .slideInAndFadeOut(from: .leading)
        case .trailing:
            .slideInAndFadeOut(from: .trailing)
        case .top, .topLeading, .topTrailing:
            .slide(from: .top)
        case .bottom, .bottomLeading, .bottomTrailing:
            .slide(from: .bottom)
        default:
            .scale()
        }
    }
}

// MARK: - Bool Modifier

public struct YTPopupContainerModifier<PopupContent: View>: ViewModifier {
    /// This modifier is driven by a Boolean
    @Binding var isPresented: Bool

    let alignment: Alignment
    let transition: YTPopupTransition

    let blurRadius: CGFloat
    let barrierColor: Color
    let barrierDismissible: Bool
    let barrierTransition: YTPopupTransition

    let padding: EdgeInsets
    let onDismiss: (() -> Void)?

    @ViewBuilder let popupContent: () -> PopupContent

    public func body(content: Content) -> some View {
        let value = isPresented

        content
            .blur(radius: value ? blurRadius : 0)
            .allowsHitTesting(!value)
            .overlay {
                ZStack(alignment: alignment) {
                    // The barrier
                    ZStack {
                        if value {
                            barrierColor
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard barrierDismissible else {
                                        return
                                    }

                                    dismiss()
                                }
                                .transition(.asymmetric(
                                    insertion: barrierTransition.insertion.transition,
                                    removal: barrierTransition.removal.transition
                                ))
                        }
                    }
                    .animation(
                        value
                            ? barrierTransition.insertion.animation
                            : barrierTransition.removal.animation,
                        value: value
                    )

                    // Content layer
                    ZStack {
                        if value {
                            popupContent()
                                .padding(padding)
                                .transition(.asymmetric(
                                    insertion: transition.insertion.transition,
                                    removal: transition.removal.transition
                                ))
                        }
                    }
                    .animation(
                        value
                            ? transition.insertion.animation
                            : transition.removal.animation,
                        value: value
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
    }

    private func dismiss() {
        isPresented = false
        onDismiss?()
    }
}

// MARK: - Item Modifier

public struct PopupItemModifier<Item: Identifiable, PopupContent: View>: ViewModifier {
    @Binding var item: Item?

    let alignment: Alignment
    let transition: YTPopupTransition

    let blurRadius: CGFloat
    let barrierColor: Color
    let barrierDismissible: Bool
    let barrierTransition: YTPopupTransition

    let padding: EdgeInsets
    let onDismiss: (() -> Void)?

    @ViewBuilder let popupContent: (Item) -> PopupContent

    public func body(content: Content) -> some View {
        let value = item

        content
            .blur(radius: value != nil ? blurRadius : 0)
            .allowsHitTesting(value == nil)
            .overlay {
                ZStack(alignment: alignment) {
                    // The barrier
                    ZStack {
                        if value != nil {
                            barrierColor
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard barrierDismissible else {
                                        return
                                    }

                                    dismiss()
                                }
                                .transition(.asymmetric(
                                    insertion: barrierTransition.insertion.transition,
                                    removal: barrierTransition.removal.transition
                                ))
                        }
                    }
                    .animation(
                        value != nil
                            ? barrierTransition.insertion.animation
                            : barrierTransition.removal.animation,
                        value: value?.id
                    )

                    // Content layer
                    ZStack {
                        if let value {
                            popupContent(value)
                                .padding(padding)
                                .transition(.asymmetric(
                                    insertion: transition.insertion.transition,
                                    removal: transition.removal.transition
                                ))
                        }
                    }
                    .animation(
                        value != nil
                            ? transition.insertion.animation
                            : transition.removal.animation,
                        value: value?.id
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
    }

    private func dismiss() {
        item = nil
        onDismiss?()
    }
}

// MARK: - API

public extension View {
    /// `transition` would be replaced by default edge movement transition if it's nil
    /// `barrierTransition` simply keep `fade` style is OK
    /// `onDismiss` only works when popup is dismissed internally
    func popupYT<C: View>(
        isPresented: Binding<Bool>,
        alignment: Alignment = .center,
        transition: YTPopupTransition? = nil,
        blurRadius: CGFloat = 0,
        barrierColor: Color = .white.opacity(0.3),
        barrierDismissible: Bool = true,
        barrierTransition: YTPopupTransition = .fade,
        padding: EdgeInsets = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> C
    ) -> some View {
        modifier(
            YTPopupContainerModifier(
                isPresented: isPresented,
                alignment: alignment,
                transition: transition ?? .slide(by: alignment),
                blurRadius: blurRadius,
                barrierColor: barrierColor,
                barrierDismissible: barrierDismissible,
                barrierTransition: barrierTransition,
                padding: padding,
                onDismiss: onDismiss,
                popupContent: content
            )
        )
    }

    func popupYT<Item: Identifiable, C: View>(
        item: Binding<Item?>,
        alignment: Alignment = .center,
        transition: YTPopupTransition? = nil,

        blurRadius: CGFloat = 0,
        barrierColor: Color = .white.opacity(0.3),
        barrierDismissible: Bool = true,
        barrierTransition: YTPopupTransition = .fade,

        padding: EdgeInsets = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> C
    ) -> some View {
        modifier(
            PopupItemModifier(
                item: item,
                alignment: alignment,
                transition: transition ?? .slide(by: alignment),
                blurRadius: blurRadius,
                barrierColor: barrierColor,
                barrierDismissible: barrierDismissible,
                barrierTransition: barrierTransition,
                padding: padding,
                onDismiss: onDismiss,
                popupContent: content
            )
        )
    }
}

// MARK: - Preview

#if DEBUG

struct DemoView: View {
    @State private var showCenter = false
    @State private var showBottom = false
    @State private var showTop = false
    @State private var alertItem: AlertModel?

    struct AlertModel: Identifiable {
        let id = UUID()
        let title: String
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Button("居中弹窗") { showCenter = true }
                Button("底部卡片") { showBottom = true }
                Button("顶部提示") { showTop = true }
                Button("Item 驱动弹窗") {
                    alertItem = AlertModel(title: "确认删除？")
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Popup Demo")
        }
        .popupYT(
            isPresented: $showCenter,
            alignment: .center,
            blurRadius: 4
        ) {
            VStack(spacing: 16) {
                Text("标题").font(.headline)
                Text("这是一个居中弹窗").foregroundStyle(.secondary)
                Button("关闭") { showCenter = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: 280)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
        .popupYT(
            isPresented: $showBottom,
            alignment: .bottom,
            blurRadius: 6,
            padding: EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        ) {
            VStack(spacing: 16) {
                Capsule()
                    .fill(.secondary)
                    .frame(width: 40, height: 4)
                Text("底部卡片").font(.headline)
                Text("从底部滑入的弹窗").foregroundStyle(.secondary)
                Button("关闭") { showBottom = false }
                    .buttonStyle(.borderedProminent)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: 20))
            .shadow(radius: 20)
        }
        .popupYT(
            isPresented: $showTop,
            alignment: .top,
            blurRadius: 4,
            padding: EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
        ) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("操作成功")
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 10)
        }
        .popupYT(item: $alertItem, alignment: .center, blurRadius: 4) { model in
            VStack(spacing: 16) {
                Text(model.title).font(.headline)
                Text("删除后不可恢复").foregroundStyle(.secondary)
                HStack {
                    Button("取消") { alertItem = nil }
                        .buttonStyle(.bordered)
                    Button("确定") { alertItem = nil }
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(maxWidth: 300)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 20)
        }
    }
}

#Preview {
    DemoView()
}

#endif
