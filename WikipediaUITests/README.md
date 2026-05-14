# Wikipedia UI Tests
This repository uses the Robots pattern for test legibility and organization. Keep this readme aligned with the checked-in workflows, schemes, test plans, and helper APIs.
## CI Lanes
- Pull requests run `.github/workflows/run_ui_tests.yml` against the `WikipediaUITests` scheme and the `English (Light)` configuration from `Test Plans/UITests.xctestplan`.
- The full localized/theme UI matrix lives in `Test Plans/UITests.xctestplan` and is exercised by `.github/workflows/run_full_ui_test_plan.yml` on manually selected release tags.
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
- For final UI-test validation, run the applicable `WikipediaUITests` test plan without narrowing to a single test configuration when the change can affect language, RTL, theme, onboarding, or launch configuration behavior.
