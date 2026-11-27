//  YTToast.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Entry point for showing a toast in the most recently active SwiftUI host.
@MainActor
public enum YTToast {
    /// Shows `content` and returns a handle for updating or dismissing that toast.
    ///
    /// - Parameter duration: Display time in seconds. `nil` uses
    ///   `style.configuration.duration`. `0` keeps the toast on screen until it is
    ///   dismissed through its handle, replaced by another toast, or updated with a
    ///   positive duration.
    @discardableResult
    public static func show(
        _ content: YTToastContent,
        style: YTToastStyle = .classic,
        duration: TimeInterval? = nil
    ) -> YTToastHandle {
        let request = YTToastRequest(
            content: content,
            style: style,
            duration: duration ?? style.configuration.duration
        )
        YTToastRegistry.enqueue(request)
        return YTToastHandle(id: request.id)
    }

    /// Dismisses the toast currently on screen, if any.
    ///
    /// Use it from an action closure when the action should close its own toast:
    /// `YTToast.show(.action(...) { YTToast.dismiss() })`.
    public static func dismiss() {
        YTToastRegistry.dismissCurrent()
    }
}

#if DEBUG

private struct YTToastPreview: View {
    @State private var blocksBackgroundInteraction = false

    private var toastConfiguration: YTToastConfiguration {
        var configuration = YTToastConfiguration.default
        configuration.interaction.blocksBackgroundInteraction = blocksBackgroundInteraction
        return configuration
    }

    var body: some View {
        VStack(spacing: 30) {
            Toggle("Block background interaction", isOn: $blocksBackgroundInteraction)

            Button("Show short HUD") {
                YTToast.show(.message("Copied color #7F9A45"), style: .classic(configuration: toastConfiguration))
            }
            Button("Show success card") {
                YTToast.show(.success(
                    "Added to Spring Garden",
                    message: "This palette is saved in your collection and can be reopened from the palette details page."
                ), style: .classic(configuration: toastConfiguration))
            }
            Button("Show failure card") {
                YTToast.show(.failure(
                    "Sync failed",
                    message: "Three palettes could not be uploaded. Check your network connection and try again."
                ), style: .classic(configuration: toastConfiguration))
            }
            Button("Show loading HUD") {
                YTToast.show(.loading("Exporting PNG…"), style: .classic(configuration: toastConfiguration), duration: 3)
            }
            Button("Show progress card") {
                YTToast.show(.progress(
                    "Syncing 12 palettes",
                    value: 0.62,
                    message: "Seven complete, five remaining. About 20 seconds left."
                ), style: .classic(configuration: toastConfiguration), duration: 4)
            }
            Button("Update progress in place") {
                let toast = YTToast.show(.progress(
                    "Syncing 12 palettes",
                    value: 0.62,
                    message: "Seven complete, five remaining. About 20 seconds left."
                ), style: .classic(configuration: toastConfiguration), duration: 4)

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.9))
                    toast.update(.progress(
                        "Syncing 12 palettes",
                        value: 0.80,
                        message: "Ten complete, two remaining. About 8 seconds left."
                    ))
                }
            }
            Button("Shrink message in place") {
                let toast = YTToast.show(.progress(
                    "Syncing 12 palettes",
                    value: 0.62,
                    message: "Seven of twelve palettes are complete. The remaining five are still downloading from the shared theme library."
                ), style: .classic(configuration: toastConfiguration), duration: 0)

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.4))
                    toast.update(.progress("Syncing 12 palettes", value: 0.80, message: "Done."))
                }
            }
            Button("Show dismissible loading HUD") {
                let toast = YTToast.show(
                    .loading("Exporting PNG…"),
                    style: .classic(configuration: toastConfiguration),
                    duration: 0
                )

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    toast.dismiss()
                }
            }
            Button("Show action card") {
                YTToast.show(.action(
                    "Deleted Spring Garden",
                    message: "Its 18 palettes have been moved to All. You can undo this deletion.",
                    actionTitle: "Undo",
                    action: {
                        YTToast.dismiss()
                        YTToast.show(.success("Deletion undone"), style: .classic(configuration: toastConfiguration))
                    }
                ), style: .classic(configuration: toastConfiguration), duration: 4)
            }
            Button("Queue two toasts") {
                YTToast.show(.success("Palette saved"), style: .classic(configuration: toastConfiguration))
                YTToast.show(.message("Color copied"), style: .classic(configuration: toastConfiguration))
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .yToastHost()
    }
}

#Preview("Toast Interaction") {
    YTToastPreview()
}

#endif
