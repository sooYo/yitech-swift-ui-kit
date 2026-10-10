//  Created by Sooyo on 2026-10-10.
//  Copyright (c) 2026 Yi Tech Studio. All rights reserved.

import SwiftUI

/// Yi Tech Studio button with consistent sizing and emphasis styles
public struct YTButton: View {
    public enum Emphasis {
        case filled
        case tinted
        case plain
    }

    private let title: String
    private let emphasis: Emphasis
    private let action: () -> Void

    public init(
        _ title: String,
        emphasis: Emphasis = .filled,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.emphasis = emphasis
        self.action = action
    }

    public var body: some View {
        switch emphasis {
        case .filled:
            button.buttonStyle(YTFilledButtonStyle())
        case .tinted:
            button.buttonStyle(YTTintedButtonStyle())
        case .plain:
            button.buttonStyle(YTPlainButtonStyle())
        }
    }

    private var button: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
        }
    }
}

private struct YTFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct YTTintedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

private struct YTPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.accentColor)
            .padding(.vertical, 12)
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}

#Preview {
    YTButton("123", emphasis: .plain) {
        
    }
}
