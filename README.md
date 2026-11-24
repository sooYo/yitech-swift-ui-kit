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
@State private var likeValue: YTLike.LikeValue = .unliked(animated: false)

YTLike(
    initialCount: 1_300,
    likeValue: $likeValue,
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

Pass `likeValue` as a binding when the parent owns the state. Each state change specifies whether to animate. For example, use `.liked(animated: false)` when initial data arrives, and `.unliked(animated: false)` for a silent external update. The initial value never animates; changing only `animated` without changing the liked state has no effect. Accepted button taps animate automatically. If `shouldStart` returns `false`, the parent can write `.liked(animated: true)` or `.unliked(animated: true)` after its own work finishes to animate that result. Omit the binding for local state.

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

`YTSelectionMenu` keeps its capsule and floating panel centered on one morphing shape. The panel does not affect the surrounding layout. On iOS and tvOS the morphing shape is drawn in the host window, so neighbouring views cannot cover it and every row stays tappable; elsewhere it is drawn in place. Bind the selected item ID; the default capsule displays the selected label or a placeholder, and rows display item labels. Supply `capsule` and `rowContent` builders to replace either or both contents. `YTSelectionMenuStyle.Panel` groups the panel background, corner, and shadow. `capsuleCornerRadius` and `rowCornerRadius` control the other two shapes independently. `YTSelectionMenuStyle.Highlighter` owns the selected row background and trailing icon; `isVisible` hides both. `Dimensions` fixes menu-owned capsule and row sizes with `YTSelectionMenuStyle.Dimensions.Size(width, height)`, so a selection change does not move the menu:

```swift
@State private var selectedID: Option.ID?

YTSelectionMenu(
    items: options,
    selection: $selectedID,
    placeholder: "Choose",
    style: .init(
        panel: .init(
            backgroundColor: .mint.opacity(0.15),
            cornerRadius: 24,
            shadow: .init()
        ),
        dimensions: .init(
            capsule: .init(160, 38),
            row: .init(236, 44)
        ),
        highlighter: .init(
            icon: Image(systemName: "checkmark.circle.fill"),
            backgroundColor: .mint.opacity(0.12)
        ),
        capsuleBackgroundColor: .white
    ),
    label: { $0.title },
    capsule: { title in
        Text(title)
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .frame(height: 38)
    },
    rowContent: { item, isSelected in
        HStack(spacing: 8) {
            Image(systemName: "paintpalette")
            Text(item.title).fontWeight(isSelected ? .semibold : .regular)
        }
        .foregroundStyle(.black)
        .padding(.leading, 12)
        .frame(width: 204, height: 44, alignment: .leading)
    }
)
```

Omit either builder to use its default `Text` content. The `capsule` builder supplies display content and is wrapped by the menu's `Button`; `rowContent` supplies display content inside each menu row's `Button`. The defaults are a 140×38 capsule and 188×34 row. The panel adds 12 points of padding and 2 points between rows. Custom content exceeding its fixed area is clipped; with a visible highlighter, the trailing 32 points of each row belong to its icon. To reuse an existing interactive component, use `trigger` and forward its action:

```swift
YTSelectionMenu(
    items: options,
    selection: $selectedID,
    label: { $0.title },
    trigger: { context in
        ExistingButton(title: context.title, action: context.open)
    }
)
```

The custom trigger keeps its natural size and owns its press feedback. `dimensions.capsule` does not resize it. Keep its background transparent when the menu's rounded rectangle should remain the single visible morphing shape.

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

## Popups

`YTPopup` presents alerts and bottom sheets from one queue. Install the host once on the root view, above tabs and navigation containers, and inject the app's appearance there:

```swift
AppRootView()
    .yPopupHost(alertStyle: .app, sheetStyle: .app)
```

The library contains no brand colors. `YTAlertStyle` and `YTSheetStyle` are value types; define `.app` in the app and pass it to the host, or override one popup with `options: .init(style: .alert(.app))`.

Queue behavior: one sheet is visible at a time and additional sheets wait in FIFO order; alerts stack above the visible sheet; closing a sheet also closes the alerts above it; a modifier's popup is cancelled when its owner disappears; identical `key` values are ignored while the first request is still queued or visible; requests made before a host exists are queued and flushed when the host appears.

Pass `entry` in `YTPopupOptions` to override the content direction (`.bottom`, `.top`, `.leading`, `.trailing`, `.scale`, `.fade`). Directional entries slide without a fade; `.automatic` keeps the sheet-bottom and alert-scale defaults.

Present directly when no view state is needed:

```swift
YTPopup.alert(
    "Delete category?",
    message: "This cannot be undone.",
    secondaryTitle: "Cancel",
    primaryTitle: "Delete",
    isDestructive: true,
    onConfirm: delete
)

let sheet = YTPopup.sheet(
    title: "Export",
    primary: YTSheetAction("Start") { export() }
) {
    ExportOptions()
}

sheet.dismiss()
```

Or attach a modifier to a view. The binding is written back to `false` when the popup closes from inside:

```swift
.ytAlert("Saved", isPresented: $showsSaved, message: "Your changes are live.", primaryTitle: "OK")

.ytSheet(isPresented: $showsExport) { dismiss in
    YTSheetView(title: "Export", onClose: dismiss) {
        ExportOptions()
    }
}

.ytSheet(item: $editorTarget) { target, dismiss in
    EditorSheet(target: target, onDismiss: dismiss)
}
```

`YTAlertView` and `YTSheetView` are the standard panels. Both accept a content slot and an optional style override. Use `YTPopup.alert(... content:)` or `YTPopup.sheet(...)` for custom content that keeps the standard chrome.

### Custom alert and sheet UI

Any single alert or sheet can draw its own complete panel. Pass `view:` with a `YTAlertPanelStyle` or `YTSheetPanelStyle`; omitting it keeps the standard `YTAlertView` / `YTSheetView`:

```swift
YTPopup.alert(
    "Delete palette?",
    message: "This action cannot be undone.",
    secondaryTitle: "Cancel",
    primaryTitle: "Delete",
    isDestructive: true,
    onConfirm: deletePalette,
    view: YTAlertPanelStyle { configuration in
        DestructiveAlertPanel(configuration: configuration)
    }
)

ExportView()
    .ytSheet(
        isPresented: $showsExport,
        title: "Export",
        primary: YTSheetAction("Start") { export() },
        view: YTSheetPanelStyle { configuration in
            CompactSheetPanel(configuration: configuration)
        }
    ) {
        ExportOptions()
    }
```

The alert builder receives a `YTAlertConfiguration`: the resolved `style` tokens, `title`, `message`, the already-wired `secondary` and `primary` actions (their handlers close the alert before running), `hasContent` with `content` for the content slot, and `dismiss` for extra close controls. The sheet builder receives a `YTSheetConfiguration` with `subtitle` and the footer actions instead. A panel owns its background, insets, and accessibility; the queue still owns the scrim, the transitions, and the dismissal callbacks. `YTAlertView(configuration:)` and `YTSheetView(configuration:)` keep the standard chrome inside a custom panel.

## Development

```bash
swift build
swift test
```
