//
//  YTSelectionMenuPanelSpec.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-22.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Geometry and colors the floating layer needs to morph the shared shape from the capsule
struct YTSelectionMenuPanelSpec {
    /// Collapsed size the shape morphs from
    let capsuleSize: CGSize

    /// Expanded size the shape morphs to
    let panelSize: CGSize

    /// Corner radius while collapsed
    let capsuleCornerRadius: Double

    /// Corner radius while expanded
    let panelCornerRadius: Double

    /// Fill while collapsed
    let capsuleColor: Color

    /// Fill while expanded
    let panelColor: Color

    /// Shadow drawn only while expanded
    let shadow: YTSelectionMenuStyle.Panel.Shadow?
}
