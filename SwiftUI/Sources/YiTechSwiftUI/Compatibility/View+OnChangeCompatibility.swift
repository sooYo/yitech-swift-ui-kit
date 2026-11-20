//
//  View+OnChangeCompatibility.swift
//  YiTechUI
//
//  Created by Sooyo on 2026-11-20.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Keeps change observation available on the package's older tvOS and watchOS targets
extension View {
    func onChangeCompatible<Value: Equatable>(
        of value: Value,
        perform action: @escaping (Value) -> Void
    ) -> some View {
        #if os(tvOS) || os(watchOS)
        onChange(of: value, perform: action)
        #else
        onChange(of: value) { _, newValue in
            action(newValue)
        }
        #endif
    }
}
