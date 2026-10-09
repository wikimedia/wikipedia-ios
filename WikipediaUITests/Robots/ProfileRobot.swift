import XCTest
import WMFComponents

/// Represents the profile screen opened from Home.
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

// MARK: - Navigation

extension ProfileRobot {
	/// Opens the app preferences from the profile sheet.
	@MainActor
	@discardableResult
	func openSettings(file: StaticString = #filePath, line: UInt = #line) -> SettingsRobot {
		let button = base.app.buttons[AccessibilityIdentifiers.Profile.settingsButton]
		let profileView = base.app.otherElements[AccessibilityIdentifiers.Profile.view]
		for _ in 0..<5 {
			if button.exists && button.isHittable { break }
			profileView.swipeUp()
		}
		base.assertVisible(button, description: "profile settings button", file: file, line: line)
		button.tap()
		return SettingsRobot(base: base).assertVisible(file: file, line: line)
	}
}
