//  YTPageIndicator.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-11.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// A compact page indicator with optional timed advancement and custom rendering.
public struct YTPageIndicator<Indicator: View>: View {
    /// Visual preset for ``PageIndicator``.
    public enum Style: Equatable {
        case extended
        case dots
        case roundedRectangle
        case timer
    }

    /// Creates a preset indicator. Pass a binding to synchronize page changes with another view.
    public init(
        count: Int,
        index: Binding<Int>? = nil,
        style: Style = .extended,
        size: CGSize = CGSize(width: 6, height: 6),
        expandedWidth: CGFloat? = nil,
        spacing: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil,
        autoAdvance: Bool? = nil,
        interval: TimeInterval = 3,
        showsPlaybackControl: Bool? = nil,
        onIndexChange: ((Int) -> Void)? = nil
    ) where Indicator == EmptyView {
        self.init(
            count: count,
            index: index,
            style: style,
            size: size,
            expandedWidth: expandedWidth,
            spacing: spacing,
            cornerRadius: cornerRadius,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            autoAdvance: autoAdvance,
            interval: interval,
            showsPlaybackControl: showsPlaybackControl,
            onIndexChange: onIndexChange,
            customIndicator: nil
        )
    }

    /// Creates an indicator whose appearance is supplied for each page.
    public init(
        count: Int,
        index: Binding<Int>? = nil,
        style: Style = .extended,
        size: CGSize = CGSize(width: 6, height: 6),
        expandedWidth: CGFloat? = nil,
        spacing: CGFloat = 8,
        cornerRadius: CGFloat? = nil,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil,
        autoAdvance: Bool? = nil,
        interval: TimeInterval = 3,
        showsPlaybackControl: Bool? = nil,
        onIndexChange: ((Int) -> Void)? = nil,
        @ViewBuilder indicatorBuilder: @escaping (Int, Double, Bool) -> Indicator
    ) {
        self.init(
            count: count,
            index: index,
            style: style,
            size: size,
            expandedWidth: expandedWidth,
            spacing: spacing,
            cornerRadius: cornerRadius,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            autoAdvance: autoAdvance,
            interval: interval,
            showsPlaybackControl: showsPlaybackControl,
            onIndexChange: onIndexChange,
            customIndicator: indicatorBuilder
        )
    }

    private let count: Int
    private let index: Binding<Int>?
    private let style: Style
    private let size: CGSize
    private let expandedWidth: CGFloat?
    private let spacing: CGFloat
    private let cornerRadius: CGFloat?
    private let activeColor: Color?
    private let inactiveColor: Color?
    private let autoAdvance: Bool?
    private let interval: TimeInterval
    private let showsPlaybackControl: Bool?
    private let onIndexChange: ((Int) -> Void)?
    private let indicatorBuilder: ((Int, Double, Bool) -> Indicator)?

    @State private var internalIndex = 0
    @State private var isPlaying = true
    @State private var cycleStartedAt = Date()
    @State private var elapsedBeforePause: TimeInterval = 0

    private var currentIndex: Int {
        guard count > 0 else {
            return 0
        }
        
        return min(max(index?.wrappedValue ?? internalIndex, 0), count - 1)
    }

    private var usesAutoAdvance: Bool {
        autoAdvance ?? (style == .timer)
    }

    private var showsPlaybackButton: Bool {
        showsPlaybackControl ?? (style == .timer)
    }

    private var resolvedActiveColor: Color {
        activeColor ?? (style == .timer ? .white : .accentColor)
    }

    private var resolvedInactiveColor: Color {
        inactiveColor ?? (style == .timer ? .white.opacity(0.28) : .secondary.opacity(0.35))
    }

    private init(
        count: Int,
        index: Binding<Int>?,
        style: Style,
        size: CGSize,
        expandedWidth: CGFloat?,
        spacing: CGFloat,
        cornerRadius: CGFloat?,
        activeColor: Color?,
        inactiveColor: Color?,
        autoAdvance: Bool?,
        interval: TimeInterval,
        showsPlaybackControl: Bool?,
        onIndexChange: ((Int) -> Void)?,
        customIndicator: ((Int, Double, Bool) -> Indicator)?
    ) {
        self.count = max(0, count)
        self.index = index
        self.style = style
        self.size = CGSize(width: max(0, size.width), height: max(0, size.height))
        self.expandedWidth = expandedWidth.map { max(size.width, $0) }
        self.spacing = max(0, spacing)
        self.cornerRadius = cornerRadius.map { max(0, $0) }
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
        self.autoAdvance = autoAdvance
        self.interval = max(0.1, interval)
        self.showsPlaybackControl = showsPlaybackControl
        self.onIndexChange = onIndexChange
        self.indicatorBuilder = customIndicator
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !shouldTick)) { context in
            let progress = progress(at: context.date)

            HStack(spacing: style == .timer ? 12 : spacing) {
                HStack(spacing: spacing) {
                    ForEach(0 ..< count, id: \.self) { itemIndex in
                        Button {
                            select(itemIndex)
                        } label: {
                            indicator(at: itemIndex, progress: progress)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if showsPlaybackButton {
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(resolvedActiveColor)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPlaying ? "Pause page playback" : "Resume page playback")
                }
            }
            .task(id: progress >= 1) {
                guard shouldTick, progress >= 1 else { return }
                advance()
            }
        }
        .task(id: index?.wrappedValue) {
            synchronizeIndex()
            resetTimer()
        }
        .accessibilityElement(children: .contain)
    }

    private var shouldTick: Bool {
        usesAutoAdvance && isPlaying && count > 1
    }

    private func progress(at date: Date) -> Double {
        guard usesAutoAdvance, count > 1 else { return 0 }
        let elapsed = elapsedBeforePause + (isPlaying ? date.timeIntervalSince(cycleStartedAt) : 0)
        return min(max(elapsed / interval, 0), 1)
    }

    @ViewBuilder
    private func indicator(at itemIndex: Int, progress: Double) -> some View {
        let active = itemIndex == currentIndex
        let itemProgress = active ? progress : 0

        if let indicatorBuilder {
            indicatorBuilder(itemIndex, itemProgress, active)
                .accessibilityLabel("Page \(itemIndex + 1) of \(count)")
                .accessibilityAddTraits(active ? .isSelected : [])
        } else if style == .timer {
            timerIndicator(at: itemIndex, active: active, progress: itemProgress)
        } else {
            presetIndicator(at: itemIndex)
        }
    }

    @ViewBuilder
    private func presetIndicator(at itemIndex: Int) -> some View {
        let active = itemIndex == currentIndex
        let corner = cornerRadius ?? size.height / 2

        switch style {
        case .extended:
            Capsule()
                .fill(active ? resolvedActiveColor : resolvedInactiveColor)
                .frame(width: active ? expandedWidth ?? size.width * 3 : size.width, height: size.height)
                .animation(.spring(response: 0.58, dampingFraction: 0.58), value: currentIndex)
                .accessibilityLabel("Page \(itemIndex + 1) of \(count)")
                .accessibilityAddTraits(active ? .isSelected : [])
        case .dots:
            Circle()
                .fill(active ? resolvedActiveColor : resolvedInactiveColor)
                .frame(width: size.width, height: size.height)
                .accessibilityLabel("Page \(itemIndex + 1) of \(count)")
                .accessibilityAddTraits(active ? .isSelected : [])
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: corner)
                .fill(active ? resolvedActiveColor : resolvedInactiveColor)
                .frame(width: size.width, height: size.height)
                .accessibilityLabel("Page \(itemIndex + 1) of \(count)")
                .accessibilityAddTraits(active ? .isSelected : [])
        case .timer:
            EmptyView()
        }
    }

    private func timerIndicator(at itemIndex: Int, active: Bool, progress: Double) -> some View {
        let trackWidth = active ? (expandedWidth ?? 36) : size.width
        let fillWidth = itemIndex < currentIndex
            ? trackWidth
            : active ? max(size.height, trackWidth * progress) : 0

        return Capsule()
            .fill(resolvedActiveColor)
            .frame(width: fillWidth)
            .frame(width: trackWidth, height: size.height, alignment: .leading)
            .background(resolvedInactiveColor, in: Capsule())
            .animation(.spring(response: 0.62, dampingFraction: 0.58), value: currentIndex)
            .accessibilityLabel(active ? "Page \(currentIndex + 1) progress" : "Page indicator")
            .accessibilityValue(active ? "\(Int(progress * 100)) percent" : "")
    }

    private func select(_ newIndex: Int) {
        guard newIndex != currentIndex else {
            return
        }
        
        setIndex(newIndex)
        resetTimer()
    }

    private func advance() {
        guard count > 1 else {
            return
        }
        
        setIndex((currentIndex + 1) % count)
        resetTimer()
    }

    private func setIndex(_ newIndex: Int) {
        if let index {
            index.wrappedValue = newIndex
        } else {
            internalIndex = newIndex
        }
        onIndexChange?(newIndex)
    }

    private func synchronizeIndex() {
        guard count > 0 else { return }
        let clamped = min(max(index?.wrappedValue ?? internalIndex, 0), count - 1)
        if let index, index.wrappedValue != clamped {
            index.wrappedValue = clamped
        } else {
            internalIndex = clamped
        }
    }

    private func togglePlayback() {
        if isPlaying {
            elapsedBeforePause += Date().timeIntervalSince(cycleStartedAt)
            isPlaying = false
        } else {
            cycleStartedAt = Date()
            isPlaying = true
        }
    }

    private func resetTimer() {
        elapsedBeforePause = 0
        cycleStartedAt = Date()
    }
}

#Preview("Page indicators") {
    VStack(spacing: 24) {
        YTPageIndicator(count: 5, style: .extended, autoAdvance: true)
        YTPageIndicator(count: 5, style: .dots)
        YTPageIndicator(count: 5, style: .roundedRectangle, size: CGSize(width: 18, height: 6))
        YTPageIndicator(count: 5, style: .timer, interval: 4)
    }
    .padding(24)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
