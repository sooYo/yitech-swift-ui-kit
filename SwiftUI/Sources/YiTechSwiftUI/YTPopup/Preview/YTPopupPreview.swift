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

                    row("Custom view · alert", systemImage: "sparkles") {
                        YTPopup.alert(
                            "Custom alert view",
                            message: "The whole panel comes from the call site.",
                            secondaryTitle: "Cancel",
                            primaryTitle: "Continue",
                            view: YTAlertPanelStyle { configuration in
                                PreviewCustomAlertPanel(configuration: configuration)
                            }
                        )
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

                    row("Custom view · sheet", systemImage: "square.on.square") {
                        YTPopup.sheet(
                            title: "Custom sheet view",
                            subtitle: YTSheetSubtitle(text: "Call-site chrome", dotColor: .purple),
                            primary: YTSheetAction("Done") {},
                            view: YTSheetPanelStyle { configuration in
                                PreviewCustomSheetPanel(configuration: configuration)
                            }
                        ) {
                            Text("Content still comes from the sheet call.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
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

// MARK: - Custom Panels

private struct PreviewCustomAlertPanel: View {
    let configuration: YTAlertConfiguration

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text(configuration.title)
                    .font(.system(size: configuration.style.titleFontSize, weight: .bold))
                    .foregroundStyle(configuration.style.titleColor)

                if let message = configuration.message {
                    Text(message)
                        .font(.system(size: configuration.style.messageFontSize))
                        .foregroundStyle(configuration.style.messageColor)
                        .multilineTextAlignment(.center)
                }
            }

            if configuration.hasContent {
                configuration.content
            }

            VStack(spacing: 10) {
                actionButton(configuration.primary, isSecondary: false)

                if let secondary = configuration.secondary {
                    actionButton(secondary, isSecondary: true)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(
            configuration.style.surface,
            in: RoundedRectangle(cornerRadius: configuration.style.cornerRadius, style: .continuous)
        )
    }

    private func actionButton(_ action: YTAlertAction, isSecondary: Bool) -> some View {
        Button(action.title, action: action.handler)
            .font(.system(size: configuration.style.actionFontSize, weight: .semibold))
            .foregroundStyle(
                isSecondary
                    ? configuration.style.secondaryForeground
                    : (action.isDestructive
                        ? configuration.style.destructiveForeground
                        : configuration.style.primaryForeground)
            )
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                isSecondary
                    ? configuration.style.secondarySurface
                    : (action.isDestructive
                        ? configuration.style.destructiveSurface
                        : configuration.style.primarySurface),
                in: RoundedRectangle(
                    cornerRadius: configuration.style.actionCornerRadius,
                    style: .continuous
                )
            )
            .buttonStyle(.plain)
            .disabled(action.isDisabled)
            .opacity(action.isDisabled ? 0.45 : 1)
    }
}

private struct PreviewCustomSheetPanel: View {
    let configuration: YTSheetConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(configuration.title)
                        .font(.system(size: configuration.style.titleFontSize, weight: .bold))
                        .foregroundStyle(configuration.style.titleColor)

                    if let subtitle = configuration.subtitle {
                        Text(subtitle.text)
                            .font(.system(size: configuration.style.subtitleFontSize))
                            .foregroundStyle(configuration.style.subtitleColor)
                    }

                    if let message = configuration.message {
                        Text(message)
                            .font(.system(size: configuration.style.messageFontSize))
                            .foregroundStyle(configuration.style.messageColor)
                    }
                }

                Spacer()

                Button(action: configuration.dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(configuration.style.iconColor)
                        .frame(width: 32, height: 32)
                        .background(configuration.style.cardSurface, in: Circle())
                }
                .buttonStyle(.plain)
            }

            configuration.content

            HStack(spacing: 10) {
                if let secondary = configuration.secondary {
                    Button(secondary.title, action: secondary.action)
                        .buttonStyle(.bordered)
                        .disabled(!secondary.isEnabled)
                }

                if let primary = configuration.primary {
                    Button(primary.title, action: primary.action)
                        .buttonStyle(.borderedProminent)
                        .disabled(!primary.isEnabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .frame(maxWidth: 460)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: configuration.style.cornerRadius,
                topTrailingRadius: configuration.style.cornerRadius
            )
            .fill(configuration.style.surface)
            .ignoresSafeArea(.container, edges: .bottom)
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
