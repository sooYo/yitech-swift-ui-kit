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

`YTLike` is a native SwiftUI like button with a count, heart, star, or thumbs-up shape, fill and stroke styling, bloom or firework particles, configurable animation timing, and animation progress callbacks:

```swift
YTLike(
    initialCount: 1_300,
    isLiked: $isLiked,
    shape: .star, // .heart by default; .thumbsUp also available
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

Pass `isLiked` as a binding when the parent owns the state. If `shouldStart` returns `false`, the parent can update `isLiked` after its own work finishes; the control then animates to the new value. Omit the binding for local state.

`YTCategoryView` displays hierarchical data conforming to `YTCategoryItem`. Bind `selectedID` when selection is parent-owned, or use `initialSelectedID` for initial navigation without a binding. `Style` configures the default chip layout and colors; `itemBuilder` replaces each chip's content, so custom chips draw their own colors:

```swift
struct Category: YTCategoryItem {
    let id: UUID
    let name: String
    let children: [Category]
}

YTCategoryView(
    items: categories,
    selectedID: $selectedCategoryID,
    onSelect: { category in
        print(category.name)
    }
) { category, isSelected, hasChildren in
    HStack(spacing: 4) {
        Text(category.name)
        if hasChildren { Image(systemName: "chevron.down") }
    }
    .fontWeight(isSelected ? .semibold : .regular)
    .foregroundStyle(isSelected ? .white : .primary)
    .padding(.horizontal, 10)
    .frame(height: 28)
    .background(isSelected ? Color.pink : Color.secondary.opacity(0.12), in: Capsule())
}
```

`YTPageIndicator` supports manual page selection and automatic playback. Set `interactionToken` when an interaction occurs outside the indicator; each token change pauses playback and resets the delay. Playback resumes after `interactionPauseDuration` seconds, which defaults to 60 seconds:

```swift
struct Pager: View {
    @State private var index = 0
    @State private var interactionToken = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $index) {
                ForEach(0 ..< 5, id: \.self) { page in
                    Text("Page \(page + 1)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            YTPageIndicator(
                count: 5,
                index: $index,
                style: .timer(),
                interval: 4,
                interactionToken: interactionToken,
                interactionPauseDuration: 60
            )
            .padding(.bottom, 20)
        }
        .simultaneousGesture(
            DragGesture()
                .onEnded { _ in
                    interactionToken += 1
                }
        )
    }
}
```

The playback button has priority over the interaction delay. Manually pausing playback cancels the pending automatic resume.

SwiftUI previews run in an Xcode app target or preview host. SPM distributes and compiles the SwiftUI source, but does not provide a standalone preview canvas.

## Development

```bash
swift build
swift test
```
