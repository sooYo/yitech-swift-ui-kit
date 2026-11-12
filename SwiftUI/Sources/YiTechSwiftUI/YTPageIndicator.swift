//  YTPageIndicator.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-11.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// A compact page indicator with optional timed advancement and custom rendering.
public struct YTPageIndicator<Indicator: View>: View {
    /// Timer-specific playback control configuration.
    public struct TimerConfiguration {
        fileprivate let playbackControl: ((Bool, @escaping () -> Void) -> AnyView)?
        public let visible: Bool

        public init(visible: Bool = true) {
            self.visible = visible
            playbackControl = nil
        }

        public init<Control: View>(
            visible: Bool = true,
            @ViewBuilder playbackControl: @escaping (Bool, @escaping () -> Void) -> Control
        ) {
            self.visible = visible
            self.playbackControl = { isPlaying, toggle in
                AnyView(playbackControl(isPlaying, toggle))
            }
        }
    }

    /// Visual preset and style-specific configuration.
    public enum Style {
        case extended
        case dots
        case roundedRectangle
        case timer(TimerConfiguration = TimerConfiguration())
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
        // Changes to this value signal user interaction outside the indicator.
        interactionToken: Int = 0,
        // Delay before automatic playback resumes after interaction.
        interactionPauseDuration: TimeInterval = 60,
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
            interactionToken: interactionToken,
            interactionPauseDuration: interactionPauseDuration,
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
        // Changes to this value signal user interaction outside the indicator.
        interactionToken: Int = 0,
        // Delay before automatic playback resumes after interaction.
        interactionPauseDuration: TimeInterval = 60,
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
            interactionToken: interactionToken,
            interactionPauseDuration: interactionPauseDuration,
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
    private let interactionToken: Int
    private let interactionPauseDuration: TimeInterval
    private let onIndexChange: ((Int) -> Void)?
    private let indicatorBuilder: ((Int, Double, Bool) -> Indicator)?

    @State private var internalIndex = 0
    @State private var isPlaying = true
    @State private var cycleStartedAt = Date()
    @State private var elapsedBeforePause: TimeInterval = 0
    @State private var interactionPauseUntil: Date?

    private var currentIndex: Int {
        guard count > 0 else {
            return 0
        }

        return min(max(index?.wrappedValue ?? internalIndex, 0), count - 1)
    }

    private var usesAutoAdvance: Bool {
        autoAdvance ?? isTimerStyle
    }

    private var showsPlaybackButton: Bool {
        timerConfiguration?.visible ?? false
    }

    private var isTimerStyle: Bool {
        if case .timer = style { return true }
        return false
    }

    private var timerConfiguration: TimerConfiguration? {
        guard case let .timer(configuration) = style else { return nil }
        return configuration
    }

    private var resolvedActiveColor: Color {
        activeColor ?? (isTimerStyle ? .white : .accentColor)
    }

    private var resolvedInactiveColor: Color {
        inactiveColor ?? (isTimerStyle ? .white.opacity(0.28) : .secondary.opacity(0.35))
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
        interactionToken: Int,
        interactionPauseDuration: TimeInterval,
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
        self.interactionToken = interactionToken
        self.interactionPauseDuration = max(0, interactionPauseDuration)
        self.onIndexChange = onIndexChange
        indicatorBuilder = customIndicator
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !shouldTick)) { context in
            let progress = progress(at: context.date)

            HStack(spacing: isTimerStyle ? 12 : spacing) {
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
                    if let customControl = timerConfiguration?.playbackControl {
                        customControl(isPlaying, togglePlayback)
                    } else {
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
        .task(id: interactionPauseUntil) {
            guard let pauseUntil = interactionPauseUntil else {
                return
            }

            do {
                try await Task.sleep(for: .seconds(max(0, pauseUntil.timeIntervalSinceNow)))
            } catch {
                return
            }

            guard isPlaying, interactionPauseUntil == pauseUntil else {
                return
            }

            cycleStartedAt = Date()
            interactionPauseUntil = nil
        }
        .onChange(of: interactionToken) {
            registerInteraction()
        }
        .accessibilityElement(children: .contain)
    }

    private var shouldTick: Bool {
        usesAutoAdvance && isPlaying && count > 1
    }

    @ViewBuilder
    private func indicator(at itemIndex: Int, progress: Double) -> some View {
        let active = itemIndex == currentIndex
        let itemProgress = active ? progress : 0

        if let indicatorBuilder {
            indicatorBuilder(itemIndex, itemProgress, active)
                .accessibilityLabel("Page \(itemIndex + 1) of \(count)")
                .accessibilityAddTraits(active ? .isSelected : [])
        } else if isTimerStyle {
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

    private func progress(at date: Date) -> Double {
        guard usesAutoAdvance, count > 1 else {
            return 0
        }

        let elapsed = elapsedBeforePause + (isPlaying && interactionPauseUntil == nil ? date.timeIntervalSince(cycleStartedAt) : 0)
        return min(max(elapsed / interval, 0), 1)
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
        registerInteraction()
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
            if interactionPauseUntil == nil {
                elapsedBeforePause += Date().timeIntervalSince(cycleStartedAt)
            }
            isPlaying = false
            interactionPauseUntil = nil
        } else {
            cycleStartedAt = Date()
            isPlaying = true
            interactionPauseUntil = nil
        }
    }

    private func registerInteraction() {
        guard usesAutoAdvance, isPlaying, interactionPauseDuration > 0 else { return }

        let now = Date()
        if interactionPauseUntil == nil {
            elapsedBeforePause += now.timeIntervalSince(cycleStartedAt)
        }
        cycleStartedAt = now
        interactionPauseUntil = now.addingTimeInterval(interactionPauseDuration)
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
        YTPageIndicator(count: 5, style: .timer(), interval: 4)
        YTPageIndicator(
            count: 5,
            style: .timer(.init(visible: false)),
            interval: 4
        )
        YTPageIndicator(
            count: 5,
            style: .timer(.init { isPlaying, toggle in
                Button(action: toggle) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }),
            interval: 4
        )
    }
    .padding(24)
    .background(Color.black)
    .preferredColorScheme(.dark)
}
