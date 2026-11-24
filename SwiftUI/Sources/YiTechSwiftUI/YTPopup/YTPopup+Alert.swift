//
//  YTPopup+Alert.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation
import SwiftUI

/// Global entry points for the popup queue.
public enum YTPopup {
    /// Dismisses every queued or visible request with `id`.
    internal static func dismiss(_ id: UUID) {
        YTPopupRegistry.dismissFromAnyThread(id: id)
    }
}

public extension YTPopup {
    /// Presents an alert with a title, optional message, and one or two actions.
    ///
    /// The alert closes before either action runs. An alert is not scrim
    /// dismissible by default; pass `options` to change that.
    @discardableResult
    static func alert(
        _ title: String,
        message: String? = nil,
        secondaryTitle: String? = nil,
        onCancel: @escaping () -> Void = {},
        primaryTitle: String,
        isDestructive: Bool = false,
        isDisabled: Bool = false,
        onConfirm: @escaping () -> Void = {},
        options: YTPopupOptions = .init(dismissible: false),
        onDismiss: (() -> Void)? = nil
    ) -> YTPopupHandle {
        let id = UUID()

        let secondary = secondaryTitle.map { secondaryTitle in
            YTAlertAction(title: secondaryTitle) {
                YTPopup.dismiss(id)
                onCancel()
            }
        }

        let primary = YTAlertAction(
            title: primaryTitle,
            isDestructive: isDestructive,
            isDisabled: isDisabled
        ) {
            guard !isDisabled else {
                return
            }

            YTPopup.dismiss(id)
            onConfirm()
        }

        let actions = YTPopupRequest.Payload(value: (secondary: secondary, primary: primary))

        enqueue(
            YTPopupRequest(
                id: id,
                kind: .alert,
                options: options,
                makeContent: {
                    let actions = actions.value

                    return AnyView(
                        YTAlertView(
                            title: title,
                            message: message,
                            secondary: actions.secondary,
                            primary: actions.primary,
                            style: alertStyle(in: options)
                        )
                    )
                },
                onDismiss: onDismiss
            )
        )

        return YTPopupHandle(id: id)
    }

    /// Presents an alert with a custom content slot.
    ///
    /// The title and buttons still come from the standard alert chrome. The
    /// alert closes before either action runs.
    @discardableResult
    static func alert<Content: View>(
        _ title: String,
        message: String? = nil,
        secondary: YTAlertAction? = nil,
        primary: YTAlertAction,
        options: YTPopupOptions = .init(dismissible: false),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> YTPopupHandle {
        let id = UUID()

        let wrappedSecondary = secondary.map { action in
            YTAlertAction(
                title: action.title,
                isDestructive: action.isDestructive,
                isDisabled: action.isDisabled
            ) {
                guard !action.isDisabled else {
                    return
                }

                YTPopup.dismiss(id)
                action.handler()
            }
        }

        let wrappedPrimary = YTAlertAction(
            title: primary.title,
            isDestructive: primary.isDestructive,
            isDisabled: primary.isDisabled
        ) {
            guard !primary.isDisabled else {
                return
            }

            YTPopup.dismiss(id)
            primary.handler()
        }

        let payload = YTPopupRequest.Payload(
            value: (secondary: wrappedSecondary, primary: wrappedPrimary, content: content)
        )

        enqueue(
            YTPopupRequest(
                id: id,
                kind: .alert,
                options: options,
                makeContent: {
                    let payload = payload.value

                    return AnyView(
                        YTAlertView(
                            title: title,
                            message: message,
                            secondary: payload.secondary,
                            primary: payload.primary,
                            style: alertStyle(in: options),
                            content: payload.content
                        )
                    )
                },
                onDismiss: onDismiss
            )
        )

        return YTPopupHandle(id: id)
    }

    private static func alertStyle(in options: YTPopupOptions) -> YTAlertStyle? {
        guard case let .alert(style)? = options.style else {
            return nil
        }

        return style
    }

    private static func enqueue(_ request: YTPopupRequest) {
        YTPopupRegistry.enqueueFromAnyThread(request)
    }
}
