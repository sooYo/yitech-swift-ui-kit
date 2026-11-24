//
//  YTPopupPreview.swift
//  YiTechUI
//
//  Created by Sooyo on 2026/11/24.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.
//

#if DEBUG && !os(watchOS)

import SwiftUI

/// Interactive preview for the popup queue.
///
/// Open this file in Xcode and resume the canvas. Switch between the
/// "Demo Style" and "System Style" variants in the canvas and tap a row to
/// present the matching popup.
struct YTPopupPreviewScreen: View {
    let alertStyle: YTAlertStyle
    let sheetStyle: YTSheetStyle

    @State private var showsQuickAlert = false
    @State private var showsCustomAlert = false
    @State private var showsQuickSheet = false
    @State private var showsCustomSheet = false
    @State private var showsLeadingSheet = false
    @State private var editorItem: PreviewEditorItem?
    @State private var paletteName = "Sunset"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                section("Alert") {
                    row("Quick alert · destructive", systemImage: "exclamationmark.bubble") {
                        showsQuickAlert = true
                    }

                    row("Custom alert · text field", systemImage: "square.and.pencil") {
                        showsCustomAlert = true
                    }
                }

                section("Sheet") {
                    row("Quick sheet · format picker", systemImage: "square.and.arrow.up") {
                        showsQuickSheet = true
                    }

                    row("Custom sheet · options", systemImage: "slider.horizontal.3") {
                        showsCustomSheet = true
                    }

                    row("Item sheet · editor", systemImage: "paintpalette") {
                        editorItem = PreviewEditorItem(title: "Edit palette")
                    }

                    row("Leading sheet · entry override", systemImage: "sidebar.left") {
                        showsLeadingSheet = true
                    }
                }

                section("Queue") {
                    row("Queue two sheets · FIFO", systemImage: "rectangle.stack") {
                        queueTwoSheets()
                    }
                }

                footer
            }
            .padding(20)
        }
        .ytAlert(
            "Delete palette?",
            isPresented: $showsQuickAlert,
            message: "This action cannot be undone.",
            secondaryTitle: "Cancel",
            primaryTitle: "Delete",
            isDestructive: true
        )
        .ytAlert(
            "Rename palette",
            isPresented: $showsCustomAlert,
            message: "The content slot keeps the standard alert chrome.",
            secondary: YTAlertAction(title: "Cancel", handler: {}),
            primary: YTAlertAction(title: "Save", handler: {})
        ) {
            PreviewNameField(name: $paletteName)
        }
        .ytSheet(
            isPresented: $showsQuickSheet,
            title: "Export palette",
            subtitle: YTSheetSubtitle(text: "PNG · 2048 × 2048", dotColor: .orange),
            message: "Choose a format, then start the export.",
            secondary: YTSheetAction("Cancel") {
                showsQuickSheet = false
            },
            primary: YTSheetAction("Export") {
                showsQuickSheet = false
            }
        ) {
            PreviewFormatList()
        }
        .ytSheet(isPresented: $showsCustomSheet) { dismiss in
            PreviewCustomSheetContent(onClose: dismiss)
        }
        .ytSheet(item: $editorItem) { item, dismiss in
            YTSheetView(title: item.title, onClose: dismiss) {
                PreviewItemSheetContent()
            }
        }
        .ytSheet(isPresented: $showsLeadingSheet, options: .init(entry: .leading)) { dismiss in
            PreviewLeadingSheetContent(onClose: dismiss)
        }
        .yPopupHost(alertStyle: alertStyle, sheetStyle: sheetStyle)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YTPopup")
                .font(.largeTitle.bold())

            Text("Alert · Sheet · Queue")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Tap a row to present. Switch Demo Style / System Style in the canvas.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        Text("Popup content that owns interactive state lives in a separate view, so the stored popup keeps updating.")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.top, 8)
    }

    private func section<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            VStack(spacing: 8) {
                content()
            }
        }
    }

    private func row(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    Color.gray.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private func queueTwoSheets() {
        YTPopup.sheet(
            title: "Queued sheet 1",
            message: "The second sheet waits until this one is closed."
        ) {
            PreviewQueuedSheetContent(index: 1)
        }

        YTPopup.sheet(
            title: "Queued sheet 2",
            message: "Only one sheet is visible at a time."
        ) {
            PreviewQueuedSheetContent(index: 2)
        }
    }
}

// MARK: - Alert Content

private struct PreviewNameField: View {
    @Binding var name: String

    var body: some View {
        TextField("Palette name", text: $name)
            .previewTextFieldStyle()
    }
}

private extension View {
    @ViewBuilder
    func previewTextFieldStyle() -> some View {
        #if os(tvOS)
        self
        #else
        textFieldStyle(.roundedBorder)
        #endif
    }
}

// MARK: - Sheet Content

private struct PreviewFormatList: View {
    private let formats = ["PNG", "SVG", "CSS"]

    @State private var selected = "PNG"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(formats, id: \.self) { format in
                Button {
                    selected = format
                } label: {
                    HStack {
                        Text(format)
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        if selected == format {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.bold))
                        }
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(
                        Color.gray.opacity(selected == format ? 0.18 : 0.10),
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }

            Button("Show alert above sheet") {
                YTPopup.alert(
                    "Alert on sheet",
                    message: "The alert is stacked above the sheet.",
                    primaryTitle: "OK"
                )
            }
            .font(.footnote.weight(.semibold))
            .padding(.top, 4)
        }
    }
}

private struct PreviewCustomSheetContent: View {
    let onClose: () -> Void

    var body: some View {
        YTSheetView(
            title: "Palette options",
            subtitle: YTSheetSubtitle(text: "3 colors", dotColor: .pink),
            message: "The custom sheet owns its layout; the modifier supplies the dismiss action.",
            onClose: onClose,
            secondary: YTSheetAction("Cancel") {
                onClose()
            },
            primary: YTSheetAction("Done") {
                onClose()
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Content can be any view.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button("Alert with a sheet action") {
                    YTPopup.alert(
                        "Close this sheet?",
                        message: "The primary action closes the sheet, which cascades back to this alert.",
                        secondaryTitle: "Cancel",
                        primaryTitle: "Close sheet",
                        onConfirm: { onClose() }
                    )
                }
                .font(.footnote.weight(.semibold))
            }
        }
    }
}

private struct PreviewLeadingSheetContent: View {
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leading sheet")
                .font(.headline)

            Text("entry: .leading")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Close") {
                onClose()
            }
            .font(.footnote.weight(.semibold))
        }
        .padding(20)
        .frame(maxWidth: 280, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.leading, 12)
    }
}

private struct PreviewItemSheetContent: View {
    var body: some View {
        Text("Closing this sheet writes the item binding back to nil.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}

private struct PreviewQueuedSheetContent: View {
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: index == 1 ? "1.circle.fill" : "2.circle.fill")
                .foregroundStyle(.orange)

            Text(index == 1 ? "First sheet in the queue." : "Second sheet in the queue.")
                .font(.footnote)
        }
    }
}

// MARK: - Data

private struct PreviewEditorItem: Identifiable {
    let id = UUID()
    let title: String
}

// MARK: - Preview Styles

private extension YTAlertStyle {
    static let previewDemo = YTAlertStyle(
        surface: Color(red: 0.12, green: 0.12, blue: 0.13),
        titleColor: .white,
        messageColor: .white.opacity(0.65),
        primarySurface: .white,
        primaryForeground: .black,
        secondarySurface: .white.opacity(0.14),
        secondaryForeground: .white,
        destructiveSurface: Color(red: 0.93, green: 0.28, blue: 0.30),
        destructiveForeground: .white
    )
}

private extension YTSheetStyle {
    static let previewDemo = YTSheetStyle(
        surface: Color(red: 0.12, green: 0.12, blue: 0.13),
        cardSurface: .white.opacity(0.10),
        borderColor: .white.opacity(0.18),
        titleColor: .white,
        subtitleColor: .white.opacity(0.55),
        messageColor: .white.opacity(0.65),
        iconColor: .white.opacity(0.70),
        primarySurface: .white,
        primaryForeground: .black,
        secondaryForeground: .white
    )
}

// MARK: - Previews

#Preview("Demo Style") {
    YTPopupPreviewScreen(alertStyle: .previewDemo, sheetStyle: .previewDemo)
}

#Preview("System Style") {
    YTPopupPreviewScreen(alertStyle: .system, sheetStyle: .system)
}

#endif
