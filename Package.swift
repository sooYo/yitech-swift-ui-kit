//  Package.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-10-10.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "YiTechUI",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "YiTechSwiftUI",
            targets: ["YiTechSwiftUI"]
        )
    ],
    targets: [
        .target(
            name: "YiTechSwiftUI",
            path: ".",
            exclude: ["README-assets", "README.md", "SwiftUI/Tests"],
            sources: ["SwiftUI/Sources/YiTechSwiftUI"]
        ),
        .testTarget(
            name: "YiTechSwiftUITests",
            dependencies: ["YiTechSwiftUI"],
            path: "SwiftUI/Tests/YiTechSwiftUITests"
        )
    ]
)
