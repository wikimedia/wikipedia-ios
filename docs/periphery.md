# Periphery

[Periphery](https://github.com/peripheryapp/periphery) finds unused Swift code: types, functions, properties, enum cases and parameters.

Run it from time to time, and always after you remove an old feature or experiment. The removal often leaves code that nothing calls.

Periphery is not part of CI. It only reports. It does not change code.

## Install

`scripts/setup` and `scripts/brew_install` install Periphery. To install it yourself:

```
brew install periphery
```

## Run

```
scripts/periphery
```

The script builds the `Wikipedia`, `WMFData` and `WMFComponents` schemes for testing. Then it builds the `Wikipedia` scheme in Debug and the `Staging` scheme, and scans the index. Each build compiles a different variant of the code (`#if TEST`, `#if DEBUG` and `#if WMF_STAGING`). If the index does not have a variant, the code that only that variant calls shows as unused.

The first run makes full builds into `build/periphery/DerivedData` and takes some minutes. Later runs are incremental. The settings are in [`.periphery.yml`](../.periphery.yml).

Do not run `periphery scan` alone. Its build step cannot choose a simulator when several iOS runtimes are installed.

Arguments go to `periphery scan`:

| Task | Command |
|---|---|
| Write a CSV file | `scripts/periphery --format csv > unused.csv` |
| Show results in Xcode format | `scripts/periphery --format xcode` |
| Save the current results | `scripts/periphery --write-baseline build/periphery/baseline.json` |
| Show only results that are not in the saved results | `scripts/periphery --baseline build/periphery/baseline.json` |
| Scan again without a build | `PERIPHERY_SKIP_BUILD=1 scripts/periphery` |
| Build on a specified simulator | `PERIPHERY_SIMULATOR_ID=<udid> scripts/periphery` |

Use a baseline before you remove a feature. Then scan with the baseline after the removal. The scan shows only the code that the removal made unused.

Use `PERIPHERY_SKIP_BUILD=1` only when no Swift file changed since the last build. If the index is older than the source, the results point to the wrong lines.

## Read the results

Periphery uses the compiler index. Thus it is correct about overloads: a call to a function with the same name in a different type does not hide an unused function. But the index has limits. Check each result for these causes before you remove code:

- **Calls from Objective-C.** Periphery cannot see them. The `retain_objc_accessible` setting keeps every `@objc` declaration and every `NSObject` member. Thus Periphery does not report unused Objective-C-visible code. Find that code by hand.
- **Code in an inactive `#if` block.** The Debug build does not compile `#if WMF_LOCAL` or release-only code, so the index does not see calls there. Search for the name in `#if` blocks.
- **Calls by name.** Code that a string, a selector name or a JavaScript message calls does not show in the index.
- **Protocol requirements.** A conformance can need a function that nothing calls. An example is `Coordinator.start()`.
- **Classes with only unused initializers.** Periphery reports the initializer, but it keeps the `NSObject` class. If you remove the only initializer, the class does not compile. Remove the whole class instead.

## Keep code on purpose

Some unused code stays in the project on purpose. Do not remove it:

- **Year in Review code.** The team keeps it as a reference for the next Year in Review.
- **The feature announcement** (`WMFFeatureAnnouncing.announceFeature` and `WMFFeatureAnnouncementViewController`). The team uses it from time to time.

To stop Periphery reporting a declaration, put a comment on the line above it:

```swift
// periphery:ignore - Only the WMF_LOCAL configuration calls this.
private static func local(options: LocalOptions) -> Configuration {
```

Always give the reason after the dash.

## Remove code

- **Remove a group, then compile.** One unused function often calls another. If a build fails after you remove one function, remove its unused callers first. Then try again.
- **Run all three test schemes.** Package tests can call internal functions that the app does not call.
- **Localized strings.** When you remove a `WMFLocalizedString` call, the build removes its key from the en, qqq and shipping files (`.strings` and `.stringsdict`). Remove the translations from `Wikipedia/Localizations/*.lproj` by hand. If a translation stays, `TWNStringsTests` can fail. This is most likely for a key with `{{PLURAL:}}`.
