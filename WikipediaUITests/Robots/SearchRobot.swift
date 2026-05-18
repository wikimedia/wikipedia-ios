import XCTest
import WMFComponents

/// Represents the standalone article search screen.
struct SearchRobot: ScreenshotCapturingRobot {
    let base: UITestRobot

    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Search.view],
            file: file,
            line: line
        )
        base.assertExists(
            base.app.searchFields[AccessibilityIdentifiers.Search.searchField],
            file: file,
            line: line
        )
        return self
    }
}
