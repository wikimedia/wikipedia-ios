import XCTest
import WMFComponents

/// Represents the profile screen opened from Explore.
struct ProfileRobot: ScreenshotCapturingRobot {
    let base: UITestRobot

    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(
            base.app.otherElements[AccessibilityIdentifiers.Profile.view],
            file: file,
            line: line
        )
        return self
    }

}
