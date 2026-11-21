//
//  YTSelectionMenuTriggerContext.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-21.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

/// Values and action supplied to an externally managed menu trigger
public struct YTSelectionMenuTriggerContext {
    public let title: String
    public let isExpanded: Bool
    public let open: () -> Void
}
