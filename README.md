# YiTech SwiftUI Kit

SwiftUI component library by Yi Tech Studio.

## Swift Package Manager

This repository is dedicated to SwiftUI. Sources live under `SwiftUI/`, and the package exposes one product: `YiTechSwiftUI`.

```swift
dependencies: [
    .package(url: "https://github.com/sooYo/yitech-swift-ui-kit.git", from: "0.1.0")
]
```

Add `YiTechSwiftUI` to an app target, then import it:

```swift
import YiTechSwiftUI
```

## Components

`YTLike` is a native SwiftUI like button with a count, heart fill and stroke styling, bloom or firework particles, configurable animation timing, and animation progress callbacks:

```swift
YTLike(
    initialCount: 1_300,
    strokeWidth: 2.3,
    fillColor: Color(red: 229 / 255, green: 72 / 255, blue: 77 / 255),
    duration: 0.42,
    burst: 50,
    effect: .bloom,
    shouldStart: { userCanLike },
    onAnimationPhaseChange: { phase in
        switch phase {
        case .started:
            break
        case .progress(let value):
            print("Progress: \(value)%")
        case .ended:
            break
        }
    }
)
```

SwiftUI previews run in an Xcode app target or preview host. SPM distributes and compiles the SwiftUI source, but does not provide a standalone preview canvas.

## Development

```bash
swift build
swift test
```
