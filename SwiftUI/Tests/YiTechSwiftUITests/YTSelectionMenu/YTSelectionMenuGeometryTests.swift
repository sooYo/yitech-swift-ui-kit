//
//  YTSelectionMenuGeometryTests.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import Testing
@testable import YiTechSwiftUI

#if os(macOS)
import AppKit
import SwiftUI

struct YTSelectionMenuGeometryTests {
    @Test @MainActor
    func defaultContentKeepsBaselineGeometry() {
        let hostingView = NSHostingView(rootView: SelectionMenuDefaultGeometryTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(hostingView.fittingSize.width - 252) < 1)
        #expect(abs(hostingView.fittingSize.height - 206) < 1)
    }

    @Test @MainActor
    func selectionChangeKeepsStageWidthFixed() {
        let model = SelectionMenuModel()
        let hostingView = NSHostingView(rootView: SelectionMenuTestHost(model: model))
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        let initialWidth = hostingView.fittingSize.width
        model.selection = "long"
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(initialWidth - 252) < 1)
        #expect(abs(hostingView.fittingSize.width - initialWidth) < 1)
    }

    @Test @MainActor
    func existingTriggerReservesStageWidth() {
        let hostingView = NSHostingView(rootView: SelectionMenuTriggerTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(hostingView.fittingSize.width - 340) < 1)
    }

    @Test @MainActor
    func configuredRowSizeSetsPanelStage() {
        let hostingView = NSHostingView(rootView: SelectionMenuCustomGeometryTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(hostingView.fittingSize.width - 300) < 1)
        #expect(abs(hostingView.fittingSize.height - 246) < 1)
    }

    @Test @MainActor
    func capsuleAndRowBuildersWorkIndependently() {
        let hostingView = NSHostingView(rootView: SelectionMenuBuilderTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(hostingView.fittingSize.width >= 252)
        #expect(hostingView.fittingSize.height > 100)
    }
}

@MainActor
private final class SelectionMenuModel: ObservableObject {
    @Published var selection: String?
}

private struct SelectionMenuTestItem: Identifiable, Hashable {
    let id: String
    let name: String
}

private struct SelectionMenuDefaultGeometryTestHost: View {
    private let items = [
        SelectionMenuTestItem(id: "one", name: "One"),
        SelectionMenuTestItem(id: "two", name: "Two"),
        SelectionMenuTestItem(id: "three", name: "Three"),
        SelectionMenuTestItem(id: "four", name: "Four")
    ]

    var body: some View {
        YTSelectionMenu(items: items, selection: .constant(nil)) { $0.name }
    }
}

private struct SelectionMenuTestHost: View {
    @ObservedObject var model: SelectionMenuModel

    private let items = [
        SelectionMenuTestItem(id: "short", name: "Short"),
        SelectionMenuTestItem(id: "long", name: "A much longer selection label")
    ]

    var body: some View {
        YTSelectionMenu(items: items, selection: $model.selection) { $0.name }
    }
}

private struct SelectionMenuTriggerTestHost: View {
    @State private var selection: String?

    private let items = [SelectionMenuTestItem(id: "short", name: "Short")]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            style: .init(dimensions: .init(capsule: .init(300, 38))),
            label: { $0.name },
            trigger: { context in
                Button(context.title, action: context.open)
                    .buttonStyle(.plain)
                    .frame(width: 300, height: 38)
            }
        )
    }
}

private struct SelectionMenuCustomGeometryTestHost: View {
    private let items = [
        SelectionMenuTestItem(id: "one", name: "One"),
        SelectionMenuTestItem(id: "two", name: "Two"),
        SelectionMenuTestItem(id: "three", name: "Three"),
        SelectionMenuTestItem(id: "four", name: "Four")
    ]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: .constant(nil),
            style: .init(dimensions: .init(row: .init(236, 44)))
        ) { $0.name }
    }
}

private struct SelectionMenuBuilderTestHost: View {
    @State private var selection: String?

    private let items = [SelectionMenuTestItem(id: "short", name: "Short")]

    var body: some View {
        VStack {
            YTSelectionMenu(
                items: items,
                selection: $selection,
                label: { $0.name },
                capsule: { Label($0, systemImage: "paintpalette") }
            )

            YTSelectionMenu(
                items: items,
                selection: $selection,
                label: { $0.name },
                rowContent: { item, _ in Label(item.name, systemImage: "paintpalette") }
            )
        }
    }
}
#endif
