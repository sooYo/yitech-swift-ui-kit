//
//  View+YTPopup.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Alert

public extension View {
    /// Presents an alert from a Boolean binding.
    ///
    /// Setting the binding to `true` enqueues an alert; setting it to `false`
    /// dismisses the alert. The binding is written back to `false` when the alert
    /// closes from inside.
    func ytAlert(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String? = nil,
        secondaryTitle: String? = nil,
        onCancel: @escaping () -> Void = {},
        primaryTitle: String,
        isDestructive: Bool = false,
        isDisabled: Bool = false,
        onConfirm: @escaping () -> Void = {},
        options: YTPopupOptions = .init(dismissible: false)
    ) -> some View {
        modifier(YTPopupFlagModifier(isPresented: isPresented) { onDismiss in
            YTPopup.alert(
                title,
                message: message,
                secondaryTitle: secondaryTitle,
                onCancel: onCancel,
                primaryTitle: primaryTitle,
                isDestructive: isDestructive,
                isDisabled: isDisabled,
                onConfirm: onConfirm,
                options: owned(options),
                onDismiss: onDismiss
            )
        })
    }

    /// Presents an alert with a custom content slot from a Boolean binding.
    func ytAlert<Content: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String? = nil,
        secondary: YTAlertAction? = nil,
        primary: YTAlertAction,
        options: YTPopupOptions = .init(dismissible: false),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(YTPopupFlagModifier(isPresented: isPresented) { onDismiss in
            YTPopup.alert(
                title,
                message: message,
                secondary: secondary,
                primary: primary,
                options: owned(options),
                onDismiss: onDismiss,
                content: content
            )
        })
    }
}

// MARK: - Sheet

public extension View {
    /// Presents a standard sheet from a Boolean binding.
    func ytSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: YTSheetSubtitle? = nil,
        message: String? = nil,
        secondary: YTSheetAction? = nil,
        primary: YTSheetAction? = nil,
        options: YTPopupOptions = .init(),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(YTPopupFlagModifier(isPresented: isPresented) { onDismiss in
            YTPopup.sheet(
                title: title,
                subtitle: subtitle,
                message: message,
                secondary: secondary,
                primary: primary,
                onDismiss: onDismiss,
                options: owned(options)
            ) {
                content()
            }
        })
    }

    /// Presents a custom sheet from a Boolean binding.
    ///
    /// The content receives a closure that dismisses the sheet.
    func ytSheet<Content: View>(
        isPresented: Binding<Bool>,
        options: YTPopupOptions = .init(),
        @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
    ) -> some View {
        modifier(YTPopupFlagModifier(isPresented: isPresented) { onDismiss in
            YTPopup.sheet(options: owned(options), onDismiss: onDismiss) { dismiss in
                content(dismiss)
            }
        })
    }

    /// Presents a custom sheet while an identifiable item is non-nil.
    ///
    /// The content receives the item and a closure that dismisses the sheet.
    /// Setting the item to `nil`, or changing its identity, closes the current sheet.
    func ytSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        options: YTPopupOptions = .init(),
        @ViewBuilder content: @escaping (Item, @escaping () -> Void) -> Content
    ) -> some View {
        modifier(
            YTPopupItemSheetModifier(
                item: item,
                options: owned(options),
                content: content
            )
        )
    }
}

// MARK: - Ownership

private func owned(_ options: YTPopupOptions) -> YTPopupOptions {
    var options = options
    options.followsOwner = true
    return options
}

// MARK: - Flag Modifier

private struct YTPopupFlagModifier: ViewModifier {
    @Binding private var isPresented: Bool

    private let makeHandle: (_ onDismiss: @escaping () -> Void) -> YTPopupHandle

    @State private var handle: YTPopupHandle? = nil
    @State private var presentationToken: UUID? = nil
    @State private var isTearingDown = false

    init(
        isPresented: Binding<Bool>,
        makeHandle: @escaping (_ onDismiss: @escaping () -> Void) -> YTPopupHandle
    ) {
        self._isPresented = isPresented
        self.makeHandle = makeHandle
    }

    func body(content: Content) -> some View {
        content
            .onAppear {
                isTearingDown = false
                sync(isPresented)
            }
            .onChangeCompatible(of: isPresented) { presented in
                sync(presented)
            }
            .onDisappear {
                isTearingDown = true
                presentationToken = nil
                handle?.dismiss()
                handle = nil
            }
    }

    private func sync(_ presented: Bool) {
        if presented {
            present()
        } else {
            presentationToken = nil
            handle?.dismiss()
            handle = nil
        }
    }

    private func present() {
        guard handle == nil else {
            return
        }

        let token = UUID()
        presentationToken = token

        handle = makeHandle { [token] in
            guard presentationToken == token else {
                return
            }

            presentationToken = nil
            handle = nil

            if !isTearingDown, isPresented {
                isPresented = false
            }
        }
    }
}

// MARK: - Item Modifier

private struct YTPopupItemSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding private var item: Item?

    private let options: YTPopupOptions
    private let content: (Item, @escaping () -> Void) -> SheetContent

    @State private var handle: YTPopupHandle? = nil
    @State private var presentedID: Item.ID? = nil
    @State private var presentationToken: UUID? = nil
    @State private var isTearingDown = false

    init(
        item: Binding<Item?>,
        options: YTPopupOptions,
        content: @escaping (Item, @escaping () -> Void) -> SheetContent
    ) {
        self._item = item
        self.options = options
        self.content = content
    }

    func body(content base: Content) -> some View {
        base
            .onAppear {
                isTearingDown = false
                sync(item)
            }
            .onChangeCompatible(of: item?.id) { _ in
                sync(item)
            }
            .onDisappear {
                isTearingDown = true
                presentationToken = nil
                handle?.dismiss()
                handle = nil
                presentedID = nil
            }
    }

    private func sync(_ value: Item?) {
        guard let value else {
            presentationToken = nil
            handle?.dismiss()
            handle = nil
            presentedID = nil
            return
        }

        guard handle == nil || presentedID != value.id else {
            return
        }

        presentationToken = nil
        handle?.dismiss()
        handle = nil

        let token = UUID()
        presentationToken = token
        presentedID = value.id

        handle = YTPopup.sheet(options: options, onDismiss: { [token] in
            guard presentationToken == token else {
                return
            }

            presentationToken = nil
            handle = nil
            presentedID = nil

            if !isTearingDown, self.item?.id == value.id {
                self.item = nil
            }
        }) { dismiss in
            content(value, dismiss)
        }
    }
}
