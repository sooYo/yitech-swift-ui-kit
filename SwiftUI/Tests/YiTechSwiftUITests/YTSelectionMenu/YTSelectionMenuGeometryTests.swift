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
    func defaultContentUsesCapsuleGeometry() {
        let hostingView = NSHostingView(rootView: SelectionMenuDefaultGeometryTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(hostingView.fittingSize.width - 140) < 1)
        #expect(abs(hostingView.fittingSize.height - 38) < 1)
    }

    @Test @MainActor
    func selectionChangeKeepsCapsuleWidthFixed() {
        let model = SelectionMenuModel()
        let hostingView = NSHostingView(rootView: SelectionMenuTestHost(model: model))
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        let initialWidth = hostingView.fittingSize.width
        model.selection = "long"
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(initialWidth - 140) < 1)
        #expect(abs(hostingView.fittingSize.width - initialWidth) < 1)
    }

    @Test @MainActor
    func existingTriggerIgnoresConfiguredCapsuleSize() {
        let hostingView = NSHostingView(rootView: SelectionMenuTriggerTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(hostingView.fittingSize.width - 300) < 1)
        #expect(abs(hostingView.fittingSize.height - 38) < 1)
    }

    @Test @MainActor
    func naturalTriggerKeepsItsIntrinsicSize() {
        let trigger = NSHostingView(rootView: SelectionMenuNaturalButton(action: {}))
        let menu = NSHostingView(rootView: SelectionMenuNaturalTriggerTestHost())
        trigger.layoutSubtreeIfNeeded()
        menu.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(menu.fittingSize.width - trigger.fittingSize.width) < 1)
        #expect(abs(menu.fittingSize.height - trigger.fittingSize.height) < 1)
    }

    @Test @MainActor
    func configuredRowSizeDoesNotChangeCapsuleGeometry() {
        let hostingView = NSHostingView(rootView: SelectionMenuCustomGeometryTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(abs(hostingView.fittingSize.width - 140) < 1)
        #expect(abs(hostingView.fittingSize.height - 38) < 1)
    }

    @Test @MainActor
    func expandedPanelDoesNotIncreaseVStackHeight() {
        let hostingView = NSHostingView(rootView: SelectionMenuExpandedGeometryTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        #expect(abs(hostingView.fittingSize.width - 120) < 1)
        #expect(abs(hostingView.fittingSize.height - 60) < 1)
    }

    @Test @MainActor
    func capsuleAndRowBuildersWorkIndependently() {
        let hostingView = NSHostingView(rootView: SelectionMenuBuilderTestHost())
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(hostingView.fittingSize.width >= 140)
        #expect(hostingView.fittingSize.height < 100)
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
            style: .init(dimensions: .init(capsule: .init(600, 100))),
            label: { $0.name },
            trigger: { context in
                Button(context.title, action: context.open)
                    .buttonStyle(.plain)
                    .frame(width: 300, height: 38)
            }
        )
    }
}

private struct SelectionMenuExpandedGeometryTestHost: View {
    @State private var selection: String?

    private let items = [
        SelectionMenuTestItem(id: "one", name: "One"),
        SelectionMenuTestItem(id: "two", name: "Two"),
        SelectionMenuTestItem(id: "three", name: "Three"),
        SelectionMenuTestItem(id: "four", name: "Four")
    ]

    var body: some View {
        VStack(spacing: 0) {
            YTSelectionMenu(
                items: items,
                selection: $selection,
                style: .init(dimensions: .init(row: .init(100, 40))),
                label: { $0.name },
                trigger: { context in
                    Button("Open", action: context.open)
                        .buttonStyle(.plain)
                        .frame(width: 120, height: 40)
                        .onAppear { context.open() }
                }
            )

            Color.clear.frame(width: 120, height: 20)
        }
    }
}

private struct SelectionMenuNaturalButton: View {
    let action: () -> Void

    var body: some View {
        Button("Select", action: action)
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }
}

private struct SelectionMenuNaturalTriggerTestHost: View {
    @State private var selection: String?

    private let items = [SelectionMenuTestItem(id: "one", name: "One")]

    var body: some View {
        YTSelectionMenu(
            items: items,
            selection: $selection,
            label: { $0.name },
            trigger: { context in
                SelectionMenuNaturalButton(action: context.open)
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
