---
name: ios-dev-setting
description: Add a new boolean developer setting toggle to the Wikipedia iOS app. Use when the user asks to "add a developer setting", "add a dev setting", "add a debug toggle", or "add a feature flag" to the iOS app.
version: 0.1.0
---

# Add an iOS Developer Setting

Adds a boolean toggle to the Developer Settings panel. Requires four edits across three packages.

## Before starting

Run `git log -1 --stat` to inspect the most recent commit. If it introduced a discrete feature or behavior change, ask the user:

> "Should I gate the feature from the last commit (`<commit subject>`) behind this developer setting?"

If yes, identify the call site automatically from the diff (`git show HEAD`) rather than asking the user for it.

If no (or if the last commit is unrelated), ask the user for these before starting:
- **camelCase name** — e.g. `allowGestureZoomArticleWebview`
- **kebab-case UserDefaults key** — e.g. `allow-gesture-zoom-article-webview`
- **UI label** — e.g. `"Allow pinch to zoom when reading articles"`
- **Call site** — which file and what behavior to gate

## 1. `WMFData/Sources/WMFData/Store/WMFUserDefaultsKey.swift`

Add a case to `WMFUserDefaultsKey`:

```swift
case myNewSetting = "my-new-setting"
```

## 2. `WMFData/Sources/WMFData/Data Controllers/Developer Settings/WMFDeveloperSettingsDataController.swift`

Add a `public var` property (default `false`):

```swift
public var myNewSetting: Bool {
    get { (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.myNewSetting.rawValue)) ?? false }
    set { try? userDefaultsStore?.save(key: WMFUserDefaultsKey.myNewSetting.rawValue, value: newValue) }
}
```

## 3. `WMFComponents/Sources/WMFComponents/Components/Developer Settings/WMFDeveloperSettingsViewModel.swift`

In `setupFormViewModel()`, instantiate and add to the items array:

```swift
let myNewSetting = WMFFormItemSelectViewModel(title: "Human-readable label", isSelected: WMFDeveloperSettingsDataController.shared.myNewSetting)
```

In `setupSubscribers()`, wire via Combine:

```swift
myNewSetting.$isSelected
    .sink { isSelected in WMFDeveloperSettingsDataController.shared.myNewSetting = isSelected }
    .store(in: &subscribers)
```

## 4. Call site

```swift
if WMFDeveloperSettingsDataController.shared.myNewSetting {
    // enable behavior
}
```

## Verify

Build in this order (see `CLAUDE.md` for full build commands):

```bash
xcodebuild -scheme WMFData ...
xcodebuild -scheme WMFComponents ...
xcodebuild -scheme Wikipedia ...
```

## Reference

Commit `1b4617f947a6772cdf77d5297ff9305f337cf116` is a complete example (`allowGestureZoomArticleWebview` gating `ignoresViewportScaleLimits` in `ArticleViewController.swift`).
