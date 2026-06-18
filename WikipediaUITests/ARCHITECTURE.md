# UI-Test Architecture

The Wikipedia iOS UI test suite is built around deterministic launch configuration, fixture-backed networking by default, stable accessibility identifiers, and robot-owned XCUITest mechanics.

## Source Of Truth

| Area | Source |
| --- | --- |
| Test target | `WikipediaUITests` in `Wikipedia.xcodeproj` |
| Test plan and configurations | `Test Plans/UITests.xctestplan` |
| Launch/runtime configuration | `WikipediaUITests/Config/UITestConfiguration.swift` |
| Launch argument keys | `WikipediaUITests/Config/UITestLaunchArgument.swift` |
| Robot contract | `WikipediaUITests/ROBOTS.md` |
| UI test authoring workflow | `WikipediaUITests/WRITING_UI_TESTS.md` and `.claude/skills/ui-test-writer/SKILL.md` |
| GitHub Actions mapping | `WikipediaUITests/GITHUB_ACTIONS.md` |
| E2E smoke subset | `WikipediaUITests/E2ESmokeTests.txt` |
| Shared accessibility identifiers | `WMFComponents/Sources/WMFComponents/Utility/AccessibilityIdentifiers.swift` |
| Fixture manifest | `WikipediaUnitTests/Fixtures/TestNetworkFixtures.json` |

## Layering

### Tests

Test files should read as short user journeys. They choose the behavior, lane, and high-level assertion. They should not own selectors, waits, gestures, scroll loops, modal dismissal, launch arguments, screenshots, or localized fallback lookup.

Good test methods are short chains of robot calls:

```swift
launchWikipediaAppRobot(onboardingState: .completed)
    .explore
    .assertVisible()
    .openSearch()
    .openArticle(named: "Dog")
    .assertVisible()
```

### Robots

Robots are the automation contract. Each robot owns one screen or cohesive flow. Robots hide XCUITest mechanics but keep semantic actions and assertions visible.

Robots should:

- return `Self` for same-screen actions;
- return the next screen robot after navigation;
- wait for the destination screen before returning it;
- forward `file` and `line` through assertions;
- keep shared actions and mechanics on the base `UITestRobot`, including common taps, scrolls, swipes, waits, screenshots, coordinate taps, back-button resolution, and dismissal helpers;
- keep screen-specific selectors and timing inside the screen robot.

Screen robots may own interaction mechanics only when the generic base action is not practical, such as WebView-specific scrolling, a control that needs a custom coordinate strategy, or a gesture whose direction depends on screen-local state.

### Accessibility Identifiers

Shared identifiers live in `AccessibilityIdentifiers.swift`. App code sets them; robots query them.

Use the Objective-C `WMFAccessibilityIdentifier` bridge only for legacy Objective-C code. Swift-only identifiers should stay as Swift constants.

Root tab, article, search, onboarding, language-selection, and image-gallery flows should use stable identifiers instead of localized visible text.

### Launch Configuration

The test plan chooses language, region, theme, and HTTP profile. `UITestConfiguration` reads those process arguments and builds app launch arguments for:

- app theme;
- preferred-language reset;
- language code and `AppleLanguages`;
- onboarding state;
- suppressing first-run or campaign surfaces;
- hiding TipKit tips;
- HTTP client profile.

Do not set language, locale, text direction, theme, simulator appearance, onboarding, or HTTP profile ad hoc in individual tests.

When a new one-time surface, campaign, modal, tip, onboarding prompt, permission prompt, or announcement makes deterministic UI tests unstable, extend the shared launch configuration instead of adding per-test dismissal code. Add a typed key to `UITestLaunchArgument`, expose the setting from `UITestConfiguration`, include the launch argument by default when it should apply suite-wide, and handle the argument once at app startup before the relevant controller can present UI.

Keep these overrides narrow and test-only. They should mark the same persisted state a user would have after dismissing or completing the one-time experience; they should not skip normal production code paths for the feature being tested.

### Network Profiles

`fixture-strict` is the default. It forwards the fixture profile to the app and routes registered HTTP(S) requests through bundled fixtures. Missing routes fail closed with fixture errors.

`e2e` is explicit. The `English (Light, E2E)` configuration passes `-WMFTestHTTPClientProfile e2e` to the UI-test process, and the app uses live networking.

### Fixtures

Fixtures should be production evidence, not hand-written approximations. Store exact API response bodies under `WikipediaUnitTests/Fixtures` and register each route in `TestNetworkFixtures.json`.

Fixture generation should cover every checked-in fixture-backed language configuration by default. Do not generate only English fixtures unless the requested behavior explicitly has a narrower language surface.

The fixture manifest should cover primary and secondary resources for a flow in every covered language, including page content, summaries, media lists, images, scripts, styles, language links, and history calls when those are part of the rendered experience.

## Patterns

### All Configurations By Default

Written UI tests should pass by default across all checked-in languages, themes, fixture-backed configurations, and E2E configurations. Do not add language, theme, or network-profile exceptions unless the requested behavior explicitly requires a narrower surface.

Fixture generation follows the same default: generate fixture coverage for all checked-in fixture-backed languages unless the requested behavior explicitly narrows the language surface.

When an exception is explicitly required, make the boundary visible in the test with direct skip logic or a focused helper near the test data. Do not hide broad capability matrices in generic robots or launch configuration.

### Fixture-Backed By Default

Most new UI coverage should run in fixture mode. It gives deterministic behavior across local runs, nightly runs, and full-plan release validation.

### E2E As A Small Smoke Surface

E2E tests are for live integration. Add them sparingly, keep them in `E2ESmokeTests.txt`, and avoid turning the E2E lane into broad regression coverage.

### One Behavior Per Test

Split independent flows when a clean launch matters. Do not call `app.terminate()` as routine cleanup between unrelated behaviors. Dismiss transient UI and assert the underlying screen remains visible.

### Explicit Configuration Boundaries

If a behavior is meaningful only in one lane or a subset of languages, make that boundary explicit at the test level. Keep fixture capability decisions out of broad robot helpers.

### Semantic Robot Assertions

If a helper verifies behavior that matters to the test, expose it as an `assert...` method and call it from the test. Action methods may wait for immediate navigation postconditions, but should not hide unrelated behavioral assertions.

### Result Bundles Before Source Guesses

When CI fails, start with the exact workflow, job, test-plan configuration, and `.xcresult` bundle. The summary, screenshots, and accessibility attachments are usually more useful than collapsed `xcpretty` output.

## Exceptions

### Visible Text Selectors

Visible text is acceptable when localization is the behavior under test or when a legacy/system control exposes no stable identifier. Keep the fallback in the robot layer and document why an identifier is unavailable.

### XCTest Skips

Avoid skip logic as a substitute for deciding the right lane. Use `XCTSkipIf` or `XCTSkipUnless` only when a checked-in configuration intentionally should not run that behavior, such as fixture-only article-control coverage in E2E or E2E-only live media coverage in fixture mode.

### Objective-C Accessibility Bridge

Add bridge values only for identifiers set or read by Objective-C code. Do not mirror every Swift identifier into Objective-C by default.

### WebView Test Hooks

Article WebView hooks may annotate real clickable DOM elements for UI tests. They should not create fake tappable elements or change production behavior. Language-specific article labels and targets belong near the article test configuration, not in generic launch configuration.

### Coordinate Taps

Prefer normal accessibility interactions. Use coordinate taps only when the result bundle or prior evidence shows XCUITest has a valid visible frame but `XCUIElement.tap()` is unreliable, such as some article WebView and gallery interactions.

### E2E Waits

Do not solve fixture-backed timing by adding sleeps. For live E2E paths, scoped longer waits can be appropriate when the app is genuinely waiting on live HTML, media metadata, image loading, or WebKit accessibility exposure.

## Maintenance

Update the UI-test docs whenever workflow triggers, test-plan configurations, launch arguments, fixture profiles, robot ownership, or accessibility contracts change.

Run `scripts/lint-ui-tests.sh` after UI-test helper changes, and use the narrowest relevant `xcodebuild` test command while iterating.
