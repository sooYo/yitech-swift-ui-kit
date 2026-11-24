//
//  YTPopupAPITests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI
import Testing
@testable import YiTechSwiftUI

struct YTPopupAPITests {
    @Test
    func popupOptionsCarryEntry() {
        #expect(YTPopupOptions().entry == .automatic)
        #expect(YTPopupOptions(entry: .leading).entry == .leading)
    }

    @Test @MainActor
    func publicEntryPointsCompose() {
        let view = PopupAPITestView()
        _ = view.body
    }
}

private struct PopupAPITestItem: Identifiable {
    let id = UUID()
}

private struct PopupAPITestView: View {
    @State private var showsQuickAlert = false
    @State private var showsCustomAlert = false
    @State private var showsQuickSheet = false
    @State private var showsCustomSheet = false
    @State private var item: PopupAPITestItem?

    var body: some View {
        Color.clear
            .yPopupHost(alertStyle: .system, sheetStyle: .system)
            .ytAlert(
                "Quick",
                isPresented: $showsQuickAlert,
                message: "Message",
                secondaryTitle: "Cancel",
                onCancel: {},
                primaryTitle: "OK",
                isDestructive: false,
                isDisabled: false,
                onConfirm: {}
            )
            .ytAlert(
                "Custom",
                isPresented: $showsCustomAlert,
                message: "Message",
                secondary: YTAlertAction(title: "Cancel", handler: {}),
                primary: YTAlertAction(title: "Save", handler: {})
            ) {
                Text("Content")
            }
            .ytSheet(
                isPresented: $showsQuickSheet,
                title: "Quick Sheet",
                subtitle: YTSheetSubtitle(text: "Subtitle"),
                message: "Message",
                secondary: YTSheetAction("Cancel") {},
                primary: YTSheetAction("Save") {}
            ) {
                Text("Content")
            }
            .ytSheet(isPresented: $showsCustomSheet) { dismiss in
                YTSheetView(
                    title: "Custom",
                    onBack: {},
                    onClose: dismiss,
                    secondary: YTSheetAction("Back") {},
                    primary: YTSheetAction("Done") {}
                ) {
                    Text("Content")
                }
            }
            .ytSheet(item: $item) { item, dismiss in
                YTSheetView(title: item.id.uuidString, onClose: dismiss) {
                    EmptyView()
                }
            }
    }
}
