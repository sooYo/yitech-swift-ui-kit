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

SwiftUI previews run in an Xcode app target or preview host. SPM distributes and compiles the SwiftUI source, but does not provide a standalone preview canvas.

## Development

```bash
swift build
swift test
```
