//
//  YTPopup+Sheet.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import Foundation
import SwiftUI

public extension YTPopup {
    /// Presents a standard bottom sheet.
    ///
    /// Footer buttons do not close the sheet by themselves, so a button can keep
    /// the sheet open while it presents an alert or changes page. Pass `view` to
    /// replace the whole sheet UI for this sheet.
    @discardableResult
    static func sheet<Content: View>(
        title: String,
        subtitle: YTSheetSubtitle? = nil,
        message: String? = nil,
        secondary: YTSheetAction? = nil,
        primary: YTSheetAction? = nil,
        onDismiss: (() -> Void)? = nil,
        view: YTSheetPanelStyle = .standard,
        options: YTPopupOptions = .init(),
        @ViewBuilder content: @escaping () -> Content
    ) -> YTPopupHandle {
        let id = UUID()

        let payload = YTPopupRequest.Payload(
            value: (
                secondary: secondary,
                primary: primary,
                view: view,
                content: content
            )
        )

        enqueue(
            YTPopupRequest(
                id: id,
                kind: .sheet,
                options: options,
                makeContent: {
                    let payload = payload.value

                    return AnyView(
                        YTSheetPanelHost(
                            title: title,
                            subtitle: subtitle,
                            message: message,
                            secondary: payload.secondary,
                            primary: payload.primary,
                            content: { AnyView(payload.content()) },
                            styleOverride: sheetStyle(in: options),
                            view: payload.view,
                            dismiss: { YTPopup.dismiss(id) }
                        )
                    )
                },
                onDismiss: onDismiss
            )
        )

        return YTPopupHandle(id: id)
    }

    /// Presents a custom bottom sheet.
    ///
    /// The content receives a closure that dismisses the sheet.
    @discardableResult
    static func sheet<Content: View>(
        options: YTPopupOptions = .init(),
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (@escaping () -> Void) -> Content
    ) -> YTPopupHandle {
        let id = UUID()
        let boxedContent = YTPopupRequest.Payload(value: content)

        enqueue(
            YTPopupRequest(
                id: id,
                kind: .sheet,
                options: options,
                makeContent: {
                    AnyView(boxedContent.value {
                        YTPopup.dismiss(id)
                    })
                },
                onDismiss: onDismiss
            )
        )

        return YTPopupHandle(id: id)
    }

    private static func sheetStyle(in options: YTPopupOptions) -> YTSheetStyle? {
        guard case let .sheet(style)? = options.style else {
            return nil
        }

        return style
    }

    private static func enqueue(_ request: YTPopupRequest) {
        YTPopupRegistry.enqueueFromAnyThread(request)
    }
}
