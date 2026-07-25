# Writing UI Tests

This guide walks through adding a `WikipediaUITests` test from setup through validation.

## Environment Setup

1. Install Xcode. Install it from the App Store or Apple Developer downloads, then open Xcode once so it can install required components.

2. Accept the Xcode license and finish first-launch setup:

   ```sh
   sudo xcodebuild -license accept
   sudo xcodebuild -runFirstLaunch
   ```

3. Select the Xcode installation that should build and run tests. If the app is installed at the workflow-style path, use:

   ```sh
   sudo xcode-select -switch /Applications/Xcode_26.2.app
   ```

   If you installed the standard App Store app, use:

   ```sh
   sudo xcode-select -switch /Applications/Xcode.app
   ```

4. Install the iOS Simulator runtime used by the workflow if it is not already installed. Open Xcode, go to Settings > Components or Settings > Platforms, and install iOS `26.2`. Confirm that Xcode sees the runtime and an `iPhone 16` simulator:

   ```sh
   xcrun simctl list runtimes
   xcrun simctl list devices available
   ```

5. Clone the repository and enter the repo root:

   ```sh
   git clone git@github.com:wikimedia/wikipedia-ios.git
   cd wikipedia-ios
   ```

6. Run the project setup script from the repository root:

   ```sh
   ./scripts/setup
   ```

   The script installs the repo's local development dependencies, including Homebrew-backed tools used by the project. Do not run it from inside the `scripts` directory; it depends on repository-relative paths.

## Use The UI Test Skill

The UI test authoring skill lives at:

```text
.claude/skills/ui-test-writer/SKILL.md
```

Use it when adding, updating, or expanding XCTest UI coverage. A useful prompt shape is:

```text
/ui-test-writer Write a ui test to exercise this flow: Navigate to the places tab. Search for "Durham". Select 'Durham, North Carolina'. Select the List toggle. Select "Cameron Indoor Stadium" from the results list. Assert the article for cameron indoor stadium has loaded.
```

If a UI test is already failing and the cause is not obvious from the result bundle, switch to using the ui-test-debugger skill located at:

```text
.claude/skills/ui-test-debugger/SKILL.md
```

That skill is for evidence-first debugging: inspect the exact failing run or local `.xcresult`, record the simulator when needed, then patch the smallest layer that matches what the test actually saw.

## Choose The Lane

Default to fixture-backed coverage. Fixture-backed tests are deterministic, run with `fixture-strict`, and should cover most app behavior.

Use E2E only when the assertion genuinely needs live services, remote media, production server behavior, or integration behavior that cannot be represented by bundled fixtures. E2E tests run through the same `WikipediaUITests` target and `UITests` test plan, but with the `English (Light, E2E)` configuration and the `e2e` HTTP client profile. Adding more than a few E2E tests without removing any will quickly balloon CI times.

The current lane split is:

| Lane | Test-plan configuration | Network profile | Primary use |
| --- | --- | --- | --- |
| Fixture UI | `English (Light)` and other localized fixture configurations | `fixture-strict` | Deterministic UI regression coverage |
| E2E smoke | `English (Light, E2E)` | `e2e` | Small live-network smoke coverage |
| Full plan | Every configuration in `Test Plans/UITests.xctestplan` | Per configuration | Release-tag confidence across language, theme, and E2E coverage |

## Add The Test

1. Name the test after the feature or flow, for example `PlacesUITests`, `ExploreUITests`, or `ArticleImageGalleryUITests`.
2. Add a new file only when the behavior is a distinct feature or flow. Otherwise extend the closest existing test file.
3. Add new Swift files to the `WikipediaUITests` target in `Wikipedia.xcodeproj`.
4. Keep the test method as a user journey. It should read like:

   ```swift
   func testUserCanCompleteFeatureJourney() throws {
       launchWikipediaAppRobot(onboardingState: .completed)
           .explore
           .assertVisible()
           .openSearch()
           .openArticle(named: "Dog")
           .assertVisible()
   }
   ```

5. Do not put raw selectors, repeated waits, gestures, alert dismissal, screenshot plumbing, scroll loops, localized fallback tables, or launch-argument setup in the test method.

## Add Or Extend Robots

Robots own XCUITest mechanics. Tests own intent.

Use one robot per screen or cohesive flow. Return the next robot when an action navigates. Keep same-screen actions returning `Self`.

Forward `file` and `line` through robot assertions:

```swift
@discardableResult
func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
    base.assertExists(
        base.app.otherElements[AccessibilityIdentifiers.Feature.view],
        file: file,
        line: line
    )
    return self
}
```

Put shared primitives on `UITestRobot` only when multiple robots need the same mechanics. Screen-specific selectors, waits, and scroll strategies belong on the screen robot.

## Add Accessibility Identifiers

Prefer stable accessibility identifiers over visible text.

1. Add Swift constants to:

   ```text
   WMFComponents/Sources/WMFComponents/Utility/AccessibilityIdentifiers.swift
   ```

2. Add `WMFAccessibilityIdentifier` Objective-C bridge values only when legacy Objective-C code needs to set or read the identifier.
3. Wire the app UI to set the identifier.
4. Query that identifier from the robot.

Use localized visible text only when localization is the behavior under test or when a legacy system control exposes no stable identifier. Keep those fallbacks in robots, not in test methods.

## Add Fixtures

For fixture-backed tests, confirm the required data already exists before writing broad robot logic around it.

1. Generate or update fixtures for every checked-in fixture-backed language configuration by default. Do not stop at English unless the requested behavior explicitly has a narrower language surface.
2. Capture real API responses from the app's production request shape for each language. Do not synthesize fixture payloads unless the test is explicitly about impossible or error states.
3. Store bodies under `WikipediaUnitTests/Fixtures`, usually in a feature folder with language-specific subfolders when the response is localized.
4. Register routes in:

   ```text
   WikipediaUnitTests/Fixtures/TestNetworkFixtures.json
   ```

5. Include secondary resources the screen needs for each language, such as summaries, mobile-html, media lists, image bytes, PCS scripts, CSS, language links, and history calls.
6. Use exact URL matching, structured `queryItems`, or `ignoreQuery` only when the query is genuinely unstable.

Strict fixture mode returns a fixture error for unregistered requests. If a test renders a partial page, inspect the failing request before adding waits.

## Add E2E Smoke Coverage

Only add an E2E smoke test when live networking is the point of the coverage.

1. The test should skip fixture-backed runs if the behavior requires E2E.
2. Validate locally with `English (Light, E2E)`.
3. Add the identifier to:

   ```text
   WikipediaUITests/E2ESmokeTests.txt
   ```

Use one XCTest identifier per line, without the `-only-testing:` prefix. The E2E workflow ignores blank lines and comments.

## Validate

Run the UI-test lint after changing test helpers, robots, launch configuration, or files that influence language and appearance:

```sh
scripts/lint-ui-tests.sh
```

Run a narrow fixture-backed test while iterating:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)" \
  -only-testing:WikipediaUITests/<ClassName>/<testMethod> \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -resultBundlePath /tmp/<case-name>/result.xcresult
```

Run a narrow E2E test when live networking is required:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light, E2E)" \
  -only-testing:WikipediaUITests/<ClassName>/<testMethod> \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -resultBundlePath /tmp/<case-name>/e2e-result.xcresult
```

Read result bundles before guessing:

```sh
xcrun xcresulttool get test-results summary --path /tmp/<case-name>/result.xcresult
```

When the change affects language, theme, RTL behavior, fixture skip logic, or release confidence, run the selected class or method through the applicable test-plan configurations instead of stopping at one English fixture-backed pass.
