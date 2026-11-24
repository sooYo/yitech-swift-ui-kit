//
//  YTPopupRequest.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// A popup waiting to be presented or already owned by a queue.
///
/// The request is created synchronously by the direct APIs, including when they
/// are called off the main thread. Building the view is deferred to the main
/// actor and happens once, when the queue presents the request. The unchecked
/// conformance carries the non-Sendable view builder across that single hop.
internal struct YTPopupRequest: @unchecked Sendable {
    /// Carries a non-Sendable payload into the main-actor content builder.
    ///
    /// The payload is created on the caller's thread and only read on the main
    /// actor when the queue builds the view.
    struct Payload<Value>: @unchecked Sendable {
        let value: Value
    }

    let id: UUID
    let kind: YTPopupKind
    let options: YTPopupOptions
    let makeContent: @MainActor () -> AnyView
    let onDismiss: (() -> Void)?

    /// The identifier defaults to a value generated at the call site.
    init(
        id: UUID = UUID(),
        kind: YTPopupKind,
        options: YTPopupOptions,
        makeContent: @escaping @MainActor () -> AnyView,
        onDismiss: (() -> Void)? = nil
    ) {
        self.id = id
        self.kind = kind
        self.options = options
        self.makeContent = makeContent
        self.onDismiss = onDismiss
    }
}
