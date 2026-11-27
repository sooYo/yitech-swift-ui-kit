//  YTToastStyle.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Owns toast content rendering while the host retains queue and presentation behavior.
public struct YTToastStyle {
    public let configuration: YTToastConfiguration
    private let makeBodyClosure: @MainActor (YTToastContent) -> AnyView

    /// Builds a custom toast using the default presentation configuration.
    public init<Body: View>(
        configuration: YTToastConfiguration = .default,
        @ViewBuilder contentBuilder: @escaping @MainActor (YTToastContent) -> Body
    ) {
        self.configuration = configuration
        self.makeBodyClosure = { content in
            AnyView(contentBuilder(content))
        }
    }

    @MainActor
    public static var classic: YTToastStyle {
        classic(configuration: .default)
    }

    @MainActor
    public static func classic(configuration: YTToastConfiguration) -> YTToastStyle {
        YTToastStyle(configuration: configuration) { content in
            YTToastClassicView(content: content, configuration: configuration)
        }
    }

    @MainActor
    func makeBody(for content: YTToastContent) -> AnyView {
        makeBodyClosure(content)
    }
}
