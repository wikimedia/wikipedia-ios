import XCTest
import WMFComponents

/// Replace `FeatureRobot` with the screen or cohesive flow this robot owns.
/// Robots centralize selectors, waits, gestures, screenshots, and navigation handoffs.
struct FeatureRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Feature.view],
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func performSameScreenAction(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Feature.primaryButton,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func openNextScreen(file: StaticString = #filePath, line: UInt = #line) -> NextScreenRobot {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Feature.nextButton,
            file: file,
            line: line
        )
        return NextScreenRobot(base: base, configuration: configuration)
            .assertVisible(file: file, line: line)
    }
}
