# Wikipedia UI Tests
This repository uses the Robots pattern for test legibility and organization. Keep these docs aligned with the checked-in workflows, schemes, test plans, and helper APIs.

## Docs
- [Writing UI Tests](WRITING_UI_TESTS.md): start-to-finish authoring guide, including environment setup and the `ui-test-writer` skill.
- [UI-Test GitHub Actions Mapping](GITHUB_ACTIONS.md): how workflows map to schemes, targets, test-plan configurations, triggers, artifacts, and purpose.
- [UI-Test Architecture](ARCHITECTURE.md): suite layering, patterns, and documented exceptions.
- [UI Test Robots](ROBOTS.md): robot-specific principles and assertion boundaries.

## CI Lanes
- `.github/workflows/run_ui_tests.yml` runs on nightly `repository_dispatch` and manual release-tag dispatch against the `WikipediaUITests` scheme and the `English (Light)` configuration from `Test Plans/UITests.xctestplan`.
- `UITestConfiguration` defaults UI-test launches to fixture mode and forwards `-WMFTestHTTPClientProfile fixture-strict` to the app.
- `.github/workflows/run_e2e_ui_tests.yml` runs on PRs targeting `main` and manual release-tag dispatch against the same scheme and test plan with the `English (Light, E2E)` configuration, narrowed to the test identifiers listed in `WikipediaUITests/E2ESmokeTests.txt`. That test-plan configuration passes `-WMFTestHTTPClientProfile e2e` to the UI-test process, so no fixture profile is forwarded to the app and the app uses E2E networking.
- `.github/workflows/run_full_ui_test_plan.yml` runs on manual dispatch from a release tag, builds `WikipediaUITests` once with `build-for-testing`, and runs each checked-in `UITests.xctestplan` configuration as a separate `test-without-building` matrix job, following the existing test-plan configurations.
- The UI-test workflows publish `.xcresult` bundles as artifacts. Use those bundles for screenshots and failure inspection.

## UI Test Robot Pattern
- Write UI tests as intent-level scripts. Test files should describe the user journey and expected result, not raw selectors, scrolling loops, alert dismissal, or screenshot plumbing.
- Put reusable UI automation in `WikipediaUITests/Robots`.
- Keep the high-level robot principles in `WikipediaUITests/ROBOTS.md`.
- Keep one robot per screen or flow. For example, `OnboardingRobot` owns welcome-screen navigation and learn-more behavior, while `PreferredLanguagesRobot` and `AllLanguagesRobot` own language-selection details.
- Return the next robot when an action navigates to another screen. For example, skipping onboarding should return `ExploreRobot`.
- Keep waits, accessibility identifiers, and screenshot attachment logic inside robots so timing and selector changes are centralized.
- Keep shared app-side accessibility identifiers in `WMFComponents/Sources/WMFComponents/Utility/AccessibilityIdentifiers.swift`, including Objective-C bridge values used by legacy screens.
- Keep launch arguments centralized in `UITestConfiguration` and `UITestLaunchArgument`. Do not set language, locale, text direction, or simulator appearance directly from individual tests.
- Prefer stable accessibility identifiers over localized visible text. Assert localized strings only when the localization behavior itself is under test.
- Write UI tests so they pass by default across all checked-in language configurations, in both fixture-backed and E2E runs. If a behavior is intentionally limited to a specific language, theme, or network profile, make that boundary explicit in the test.
- Generate fixture data for every checked-in fixture-backed language configuration by default, not just English. Add narrower fixture coverage only when the requested test behavior explicitly has a narrower language surface.
- Keep fixture-backed article-control tests locale-aware through `ArticleControlsFixture`. The fixture-backed `en`, `de`, `he`, and `vi` configurations should open the active language's Dog article through search and load bundled article resources from `WikipediaUnitTests/Fixtures/ArticleControls/<language-code>`; E2E, unsupported languages, and language configurations irrelevant to a specific assertion should skip with XCTest skip APIs.

## Validation
- For UI-test helper changes, first run `scripts/lint-ui-tests.sh`.
- For compile validation, use a narrow `xcodebuild build-for-testing` or selected UI-test run while iterating.
- For development and final UI-test verification, run the default fixture-backed `WikipediaUITests` scheme with the `UITests` test plan narrowed to `English (Light)`:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)" \
  -destination "platform=iOS Simulator,name=iPhone 16"
```

- To run the same UI tests locally as E2E tests, select the E2E test-plan configuration:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light, E2E)" \
  -destination "platform=iOS Simulator,name=iPhone 16"
```
