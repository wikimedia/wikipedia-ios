# Wikipedia UI Tests
This repository uses the Robots pattern for test legibility and organization. Keep this readme aligned with the checked-in workflows, schemes, test plans, and helper APIs.
## CI Lanes
- Pull requests run `.github/workflows/run_ui_tests.yml` against the `WikipediaUITests` scheme and the `English (Light)` configuration from `Test Plans/UITests.xctestplan`.
- The remaining localized/theme configurations live in `Test Plans/UITests.xctestplan`, but they are not the normal development or verification path. Run them only for explicitly requested full-matrix validation or a configuration-specific investigation.
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
## Validation
- For UI-test helper changes, first run `scripts/lint-ui-tests.sh`.
- For compile validation, use a narrow `xcodebuild build-for-testing` or selected UI-test run while iterating.
- For development and final UI-test verification, run the `WikipediaUITests` scheme with the `UITests` test plan narrowed to `English (Light)`:

```sh
xcodebuild test \
  -scheme WikipediaUITests \
  -project Wikipedia.xcodeproj \
  -testPlan UITests \
  -only-test-configuration "English (Light)" \
  -destination "platform=iOS Simulator,name=iPhone 16"
```
