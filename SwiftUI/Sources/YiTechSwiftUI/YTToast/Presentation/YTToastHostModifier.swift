//  YTToastHostModifier.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

internal struct YTToastHostModifier: ViewModifier {
    @StateObject private var center = YTToastCenter()
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .overlay {
                YTToastHostView(center: center)
            }
            .onAppear {
                YTToastRegistry.install(center)
            }
            .onDisappear {
                YTToastRegistry.uninstall(center)
            }
            .onChangeCompatible(of: scenePhase) { phase in
                guard phase == .active else {
                    return
                }
                YTToastRegistry.markActive(center)
            }
    }
}

public extension View {
    /// Installs one toast overlay on a SwiftUI root view.
    func yToastHost() -> some View {
        modifier(YTToastHostModifier())
    }
}
