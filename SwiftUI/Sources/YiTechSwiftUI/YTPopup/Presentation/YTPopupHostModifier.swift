//
//  YTPopupHostModifier.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI

/// Installs the popup overlay on the root view and registers it for routing.
internal struct YTPopupHostModifier: ViewModifier {
    private let alertStyle: YTAlertStyle
    private let sheetStyle: YTSheetStyle

    @StateObject private var center = YTPopupCenter()
    @Environment(\.scenePhase) private var scenePhase

    init(alertStyle: YTAlertStyle, sheetStyle: YTSheetStyle) {
        self.alertStyle = alertStyle
        self.sheetStyle = sheetStyle
    }

    func body(content: Content) -> some View {
        content
            .allowsHitTesting(!center.hasPopups)
            .overlay {
                YTPopupRootView(center: center)
                    .environment(\.ytAlertStyle, alertStyle)
                    .environment(\.ytSheetStyle, sheetStyle)
            }
            .onAppear {
                YTPopupRegistry.install(center)
            }
            .onDisappear {
                YTPopupRegistry.uninstall(center)
            }
            .onChangeCompatible(of: scenePhase) { phase in
                guard phase == .active else {
                    return
                }

                YTPopupRegistry.markActive(center)
            }
    }
}

public extension View {
    /// Installs the global popup host.
    ///
    /// Attach this once to the root view, above tabs and navigation containers,
    /// so popups can cover the whole window. Colors and other appearance values
    /// come from the supplied styles; the library holds no brand tokens.
    func yPopupHost(
        alertStyle: YTAlertStyle = .system,
        sheetStyle: YTSheetStyle = .system
    ) -> some View {
        modifier(YTPopupHostModifier(alertStyle: alertStyle, sheetStyle: sheetStyle))
    }
}
