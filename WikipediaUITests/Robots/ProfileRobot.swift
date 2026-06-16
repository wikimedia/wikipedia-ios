import XCTest
import WMFComponents

/// Represents the profile screen opened from Explore.
struct ProfileRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
}

// MARK: - Screen state

extension ProfileRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Profile.view],
            file: file,
            line: line
        )
        return self
    }
}
