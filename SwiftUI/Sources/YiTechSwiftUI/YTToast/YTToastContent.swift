//  YTToastContent.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-27.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Semantic content shared by the built-in and custom toast builders.
public enum YTToastContent {
    case message(String)
    case success(String, message: String? = nil, icon: Image? = nil)
    case failure(String, message: String? = nil, icon: Image? = nil)
    case loading(String, message: String? = nil, icon: Image? = nil)
    
    /// `value` is a fraction from 0 to 1. The classic renderer clamps values to that range.
    case progress(String, value: Double, message: String? = nil)
    
    /// Runs `action` when the action button is tapped.
    case action(String, message: String, actionTitle: String, icon: Image? = nil, action: @MainActor () -> Void)
}
