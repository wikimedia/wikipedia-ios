---
name:ui-test-writer
description: Use when adding, updating, or expanding XCTest UI coverage in the Wikipedia iOS app's WikipediaUITests target. Writes journey-first UI tests with robots, deterministic launch configuration, and fixture-backed defaults.
---

# UI Test Writer

Use this skill to write PR-stable UI tests for `WikipediaUITests` with minimal boilerplate in each test file.

## Required context to load first

1. Read these repository docs before writing code:
   - `WikipediaUITests/README.md`
   - `WikipediaUITests/ROBOTS.md`
2. Inspect nearby examples before choosing a pattern:
   - Existing test files in `WikipediaUITests/*UITests.swift`
   - Existing robots in `WikipediaUITests/Robots`
   - Configuration for UI test runs:
     - `WikipediaUITests/Config/UITestConfiguration.swift`
     - `WikipediaUITests/Config/UITestLaunchArgument.swift`

## Core rules

- Write test methods using the Robots pattern documented in `WikipediaUITests/ROBOTS.md`
- Keep raw `XCUIApplication` selectors, waits, gestures, screenshots, scrolling, modal handling, and timing details inside robots.
- Prefer one robot per screen or cohesive flow.
- Return the next robot when an action navigates to another screen.
- Use `launchWikipediaAppRobot(...)` instead of hand-rolling app launch setup.
- Centralize launch state in `UITestConfiguration` and `UITestLaunchArgument`; do not set theme, language, onboarding, locale, HTTP profile, or simulator appearance ad hoc in individual tests.
- Default to fixture-backed coverage with `fixture-strict`; use live networking when E2E is specified.
- Prefer shared accessibility identifiers from `AccessibilityIdentifiers.swift` over localized visible text.
- STRONGLY prefer targeting elements based their accessibility identifier.
- Assert localized strings only when localization is the behavior under test.
- NEVER `XCTSkipUnless` / `XCTSkipIf` unless specifically directed to do so.
- Forward `file: StaticString = #filePath` and `line: UInt = #line` through robot assertions so failures point to the calling test.

## Minimal test skeleton

When creating a new test file, start from the packaged template:

- [UITestFileSkeleton.swift](templates/UITestFileSkeleton.swift)

The skeleton intentionally relies on `launchWikipediaAppRobot` and existing robots so each new test needs only:

1. A specific test class name.
2. The short robot journey.
3. Small helper methods only when they remove repeated journey setup.

If the journey needs new screen mechanics, add or extend a robot instead of adding selectors to the test. Use this companion template only when a new robot is needed:

- [RobotSkeleton.swift](templates/RobotSkeleton.swift)

## Test Fixtures

Before writing a test, determine if appropriate fixture data is present. If not present, execute the following steps to build out new fixture data:
1. Fixtures are captured from the live Wikipedia/MediaWiki APIs, not synthesized.
2. Reproduce the request the app makes, including the app's iOS `User-Agent`, `Accept`, and `Accept-Language` headers, then save the exact response body under `WikipediaUnitTests/Fixtures`.
3. Register the route in `WikipediaUnitTests/Fixtures/TestNetworkFixtures.json` with the request matcher, status, response headers, and `bodyResource`.
4. Keep payloads byte-for-byte aligned with the API response; when `fixture-strict` mode hits an unregistered request, it returns a JSON 501 with the exact method and URL to add.


## Workflow

1. Clarify the user-visible behavior to cover, the expected result, and whether the scenario can run with fixture-backed networking.
2. Choose where the test belongs:
   - Existing `*UITests.swift` file for related behavior.
   - New `FeatureUITests.swift` file only when the coverage is a distinct feature or flow.
3. Adhere to established Robot testing pattern by following examples laid out by existing tests.
4. Add accessibility identifiers to target UI elements
   - Add constants to `AccessibilityIdentifiers.swift`.
   - Add `WMFAccessibilityIdentifier` Objective-C bridge values if legacy Objective-C/UIKit code needs them.
   - Wire app code to set the identifier.
5. Add deterministic launch configuration only through `UITestConfiguration` / `UITestLaunchArgument`.
6. Validate narrowly:
   - `scripts/lint-ui-tests.sh`
   - For local validation, prefer the latest installed iOS 26 simulator destination
   - Targeted UI-test run, for example:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:WikipediaUITests/<ClassName>/<testName>
```

For E2E tests:
- run with `-only-test-configuration "English (Light, E2E)"`
- add the test identifier to `WikipediaUITests/E2ESmokeTests.txt` to include tests in the E2E smoke lane.
