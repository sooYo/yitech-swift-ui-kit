//
//  YTPopupPanelStyleTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/25.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

import SwiftUI
import Testing
@testable import YiTechSwiftUI

@Suite(.serialized)
struct YTPopupPanelStyleTests {
    @Test @MainActor
    func customAlertViewReceivesConfiguration() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)

        let recorder = AlertRecorder()

        YTPopup.alert(
            "Title",
            message: "Message",
            secondaryTitle: "Cancel",
            primaryTitle: "OK",
            view: YTAlertPanelStyle { configuration in
                let _ = recorder.capture(configuration)
                Color.clear
            }
        )

        render(YTPopupRootView(center: center))

        #expect(recorder.configuration?.title == "Title")
        #expect(recorder.configuration?.message == "Message")
        #expect(recorder.configuration?.hasContent == false)
        #expect(recorder.configuration?.secondary?.title == "Cancel")
        #expect(recorder.configuration?.primary.title == "OK")
    }

    @Test @MainActor
    func customAlertViewReceivesContentSlot() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)

        let recorder = AlertRecorder()

        YTPopup.alert(
            "Title",
            primary: YTAlertAction(title: "OK", handler: {}),
            view: YTAlertPanelStyle { configuration in
                let _ = recorder.capture(configuration)
                configuration.content
            }
        ) {
            Text("Slot")
        }

        render(YTPopupRootView(center: center))

        #expect(recorder.configuration?.hasContent == true)
    }

    @Test @MainActor
    func customAlertViewReceivesStyleOverride() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)

        let recorder = AlertRecorder()
        let style = YTAlertStyle(
            surface: .black,
            titleColor: .white,
            messageColor: .gray,
            primarySurface: .white,
            primaryForeground: .black,
            secondarySurface: .gray,
            secondaryForeground: .white,
            destructiveSurface: .red,
            destructiveForeground: .white,
            titleFontSize: 21
        )

        YTPopup.alert(
            "Title",
            primaryTitle: "OK",
            view: YTAlertPanelStyle { configuration in
                let _ = recorder.capture(configuration)
                Color.clear
            },
            options: .init(style: .alert(style))
        )

        render(YTPopupRootView(center: center))

        #expect(recorder.configuration?.style.titleFontSize == 21)
    }

    @Test @MainActor
    func eachAlertKeepsItsOwnView() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)

        let firstRecorder = AlertRecorder()
        let secondRecorder = AlertRecorder()

        YTPopup.alert(
            "First",
            primaryTitle: "OK",
            view: YTAlertPanelStyle { configuration in
                let _ = firstRecorder.capture(configuration)
                Color.clear
            }
        )

        YTPopup.alert(
            "Second",
            primaryTitle: "OK",
            view: YTAlertPanelStyle { configuration in
                let _ = secondRecorder.capture(configuration)
                Color.clear
            }
        )

        render(YTPopupRootView(center: center))

        #expect(firstRecorder.configuration?.title == "First")
        #expect(secondRecorder.configuration?.title == "Second")
    }

    @Test @MainActor
    func customAlertViewDismissClosesRequest() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)

        let recorder = AlertRecorder()
        var dismissCount = 0

        let handle = YTPopup.alert(
            "Title",
            primaryTitle: "OK",
            view: YTAlertPanelStyle { configuration in
                let _ = recorder.capture(configuration)
                Color.clear
            },
            onDismiss: { dismissCount += 1 }
        )

        render(YTPopupRootView(center: center))
        recorder.configuration?.dismiss()

        #expect(center.layers.first?.state == .dismissing)

        center.completeRemoval(id: handle.id)

        #expect(dismissCount == 1)
        #expect(center.layers.isEmpty)
    }

    @Test @MainActor
    func customSheetViewReceivesConfiguration() {
        YTPopupRegistry.reset()
        defer { YTPopupRegistry.reset() }

        let center = makeCenter()
        YTPopupRegistry.install(center)

        let recorder = SheetRecorder()

        YTPopup.sheet(
            title: "Sheet",
            subtitle: YTSheetSubtitle(text: "Subtitle"),
            message: "Message",
            secondary: YTSheetAction("Cancel") {},
            primary: YTSheetAction("Done") {},
            view: YTSheetPanelStyle { configuration in
                let _ = recorder.capture(configuration)
                Color.clear
            }
        ) {
            Text("Content")
        }

        render(YTPopupRootView(center: center))

        #expect(recorder.configuration?.title == "Sheet")
        #expect(recorder.configuration?.subtitle?.text == "Subtitle")
        #expect(recorder.configuration?.message == "Message")
        #expect(recorder.configuration?.secondary?.title == "Cancel")
        #expect(recorder.configuration?.primary?.title == "Done")
    }

    @Test @MainActor
    func panelViewsAcceptConfigurations() {
        let alert = YTAlertConfiguration(
            title: "Title",
            message: nil,
            secondary: nil,
            primary: YTAlertAction(title: "OK", handler: {}),
            style: .system,
            hasContent: false,
            content: AnyView(EmptyView()),
            dismiss: {}
        )

        _ = YTAlertView(configuration: alert)

        let sheet = YTSheetConfiguration(
            title: "Title",
            subtitle: nil,
            message: nil,
            secondary: nil,
            primary: nil,
            style: .system,
            content: AnyView(EmptyView()),
            dismiss: {}
        )

        _ = YTSheetView(configuration: sheet)
    }
}

private extension YTPopupPanelStyleTests {
    @MainActor
    func makeCenter() -> YTPopupCenter {
        let center = YTPopupCenter()
        center.animatesTransitions = false
        return center
    }

    @MainActor
    func render<Content: View>(_ content: Content) {
        let renderer = ImageRenderer(content: content.frame(width: 390, height: 640))
        renderer.scale = 1
        _ = renderer.cgImage
    }
}

private final class AlertRecorder {
    private(set) var configuration: YTAlertConfiguration?

    func capture(_ configuration: YTAlertConfiguration) {
        self.configuration = configuration
    }
}

private final class SheetRecorder {
    private(set) var configuration: YTSheetConfiguration?

    func capture(_ configuration: YTSheetConfiguration) {
        self.configuration = configuration
    }
}
