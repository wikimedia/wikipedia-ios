# UI Test Robots
Robots are the UI test automation contract for the Wikipedia app. Test files should read as short user journeys, while robots own the XCUITest mechanics needed to make those journeys reliable across localized, themed, and RTL test-plan configurations.

## Principles
- Keep tests intent-level. A test should say what the user does and what result matters, not how to find a button, dismiss a sheet, scroll a table, or attach a screenshot.
- Keep one robot per screen or cohesive flow. Screen robots own selectors and waits for one UI surface. Flow robots can coordinate multi-step journeys when the flow itself is the behavior under test.
- Return the next robot after navigation. Actions such as opening Profile or skipping onboarding should return the robot for the screen that appears next.
- Centralize selectors and launch configuration. Use shared accessibility identifiers, `UITestConfiguration`, and `UITestLaunchArgument` rather than raw strings, ad hoc launch arguments, or direct simulator state changes in tests.
- Prefer stable accessibility identifiers over visible text. Assert localized strings only when localization behavior is the point of the test.
- Make theme, language, and RTL behavior robot-owned when it affects interaction. Tests should not know whether a page swipe goes left or right in a particular language.
- Keep assertions semantic and visible. Robots can hide wait mechanics, but method names should still describe the assertion being made.
- Keep robots thin. Do not turn them into a second test framework or hide unrelated journeys behind broad helper methods.
- Forward `file` and `line` through robot assertions so failures point back to the calling test.
- Move code into a robot when it would otherwise duplicate selectors, waits, launch setup, screenshot attachment, modal handling, or scrolling behavior.
## Adding Coverage
When adding a UI test, start with the test method as an intent-level script. If the test needs raw `XCUIApplication` queries, repeated waits, launch argument setup, or screen-specific interaction details, add or extend the relevant robot instead of keeping those mechanics in the test file.
