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

    /// The logged-out layout: the "Log in / Join Wikipedia" row without the temporary account user row.
    @discardableResult
    func assertShowsLoggedOutAccount(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.buttons[AccessibilityIdentifiers.Profile.joinWikipediaRow],
            file: file,
            line: line
        )
        XCTAssertFalse(
            base.app.buttons[AccessibilityIdentifiers.Profile.temporaryAccountUserPageRow].exists,
            "Expected the profile not to show the temporary account user row.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertShowsTemporaryAccount(username: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let userPageRow = base.app.buttons[AccessibilityIdentifiers.Profile.temporaryAccountUserPageRow]
        base.assertExists(userPageRow, file: file, line: line)
        XCTAssertEqual(userPageRow.label, username, file: file, line: line)
        return self
    }
}
