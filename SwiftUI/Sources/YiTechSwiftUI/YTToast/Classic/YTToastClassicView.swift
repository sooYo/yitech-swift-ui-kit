//  YTToastClassicView.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Renders the centered HUD from the light and dark Ardot toast designs.
struct YTToastClassicView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let content: YTToastContent
    let configuration: YTToastConfiguration

    var body: some View {
        let appearance = appearance
        Group {
            if case .progress = content {
                progressCard(appearance)
            } else {
                messageCard(appearance)
            }
        }
        .padding(.horizontal, isLongForm ? 16 : (hasSemanticIcon ? 16 : 18))
        .padding(.vertical, isLongForm ? 16 : 11)
        .background(
            appearance.background.material,
            in: isLongForm ? appearance.background.longFormShape : appearance.background.shape
        )
        .overlay {
            (isLongForm ? appearance.background.longFormShape : appearance.background.shape)
                .fill(appearance.background.color)
                .overlay {
                    (isLongForm ? appearance.background.longFormShape : appearance.background.shape)
                        .stroke(appearance.background.borderColor, lineWidth: 0.5)
                }
        }
        .shadow(color: appearance.background.shadowColor, radius: 15, x: 0, y: 5)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var title: String {
        switch content {
        case .message(let text),
             .success(let text, _, _),
             .failure(let text, _, _),
             .loading(let text, _, _),
             .progress(let text, _, _),
             .action(let text, _, _, _, _):
            text
        }
    }

    private var message: String? {
        switch content {
        case .success(_, let message, _),
             .failure(_, let message, _),
             .loading(_, let message, _),
             .progress(_, _, let message):
            message
        case .action(_, let message, _, _, _):
            message
        case .message:
            nil
        }
    }

    private var isLongForm: Bool {
        if case .progress = content {
            return true
        }

        if case .action = content {
            return true
        }

        return message != nil
    }

    private func messageCard(_ appearance: YTToastConfiguration) -> some View {
        // A single-line HUD has no message row, so centering the title against the
        // icon needs a centered stack; multi-line cards align their first lines.
        HStack(alignment: isLongForm ? .top : .center, spacing: 16) {
            if hasSemanticIcon {
                YTToastClassicSemanticIcon(
                    color: semanticIconColor,
                    showDelay: configuration.animation.show.duration
                ) {
                    semanticIcon
                }
                .frame(width: 20, height: 20, alignment: .center)
                .padding(.top, isLongForm ? 2 : 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(appearance.text.font)
                    .foregroundStyle(appearance.text.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)

                if let message {
                    Text(message)
                        .font(appearance.message.font)
                        .foregroundStyle(appearance.message.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }

                if case .action(_, _, let actionTitle, _, let action) = content {
                    HStack {
                        Spacer(minLength: 0)
                        Button(actionTitle, action: action)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.top, 12)
                }
            }
        }
        .frame(maxWidth: isLongForm ? .infinity : nil, alignment: .leading)
    }

    private func progressCard(_ appearance: YTToastConfiguration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(appearance.text.font)
                    .foregroundStyle(appearance.text.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentTransition(.opacity)

                if case .progress(_, let value, _) = content {
                    Text("\(Int(value * 100))%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(appearance.message.color)
                        .contentTransition(.opacity)
                }
            }

            if let message {
                Text(message)
                    .font(appearance.message.font)
                    .foregroundStyle(appearance.message.color)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }

            if case .progress(_, let value, _) = content {
                progressBar(appearance, value: value)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The determinate bar, drawn by hand so a value change sweeps instead of snapping.
    ///
    /// `ProgressView` animates its fill on its own schedule, which is both shorter than
    /// the card's resize and out of step with it; a capsule pair keeps the sweep and the
    /// layout change on the same curve.
    private func progressBar(_ appearance: YTToastConfiguration, value: Double) -> some View {
        let fraction = min(max(value, 0), 1)
        let tint = appearance.progress.tint

        return GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(tint.opacity(0.18))

                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 5)
        // Rasterising the bar keeps the material from washing the tint out, which is
        // what a plain shape fill over `.ultraThinMaterial` would otherwise do.
        .drawingGroup()
        .animation(reduceMotion ? nil : .easeInOut(duration: Timing.progressUpdate), value: fraction)
        .accessibilityElement()
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text("\(Int(fraction * 100))%"))
    }

    @ViewBuilder
    private var semanticIcon: some View {
        switch content {
        case .message, .progress:
            EmptyView()
        case .success(_, _, let icon):
            if let icon {
                icon
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.227, green: 0.620, blue: 0.388))
            }
        case .failure(_, _, let icon):
            if let icon {
                icon
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(red: 0.83, green: 0.28, blue: 0.28))
            }
        case .loading(_, _, let icon):
            if let icon {
                icon
            } else {
                ProgressView().controlSize(.small)
            }
        case .action(_, _, _, let icon, _):
            if let icon {
                icon
            } else {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hasSemanticIcon: Bool {
        switch content {
        case .message, .progress:
            false
        case .success, .failure, .loading, .action:
            true
        }
    }

    private var semanticIconColor: Color {
        switch content {
        case .success:
            Color(red: 0.227, green: 0.620, blue: 0.388)
        case .failure:
            Color(red: 0.83, green: 0.28, blue: 0.28)
        case .loading:
            .accentColor
        case .action:
            .secondary
        case .message, .progress:
            .primary
        }
    }

    private enum Timing {
        /// Sweep of the determinate progress bar towards its new value.
        static let progressUpdate: TimeInterval = 0.3
    }

    private var appearance: YTToastConfiguration {
        var configuration = configuration
        guard colorScheme == .dark else {
            return configuration
        }

        configuration.text.color = Color(red: 0.949, green: 0.945, blue: 0.918)
        configuration.message.color = .white.opacity(0.4)
        configuration.background.color = Color.black.opacity(0.2)
        configuration.background.borderColor = .white.opacity(0.1)
        configuration.background.shadowColor = .black.opacity(0.45)
        return configuration
    }
}
