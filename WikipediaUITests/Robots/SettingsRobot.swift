import XCTest
import WMFComponents

/// Represents app preferences, including the persisted immersive-mode switch.
struct SettingsRobot: ScreenshotCapturingRobot {
	let base: UITestRobot

	/// Waits for the preferences screen presented from Profile.
	@MainActor
	@discardableResult
	func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
		base.assertExists(settingsView, description: "settings screen", file: file, line: line)
		return self
	}

	/// Scrolls to the immersive-mode switch and checks its accessible on/off value.
	@MainActor
	@discardableResult
	func assertImmersiveModeEnabled(_ enabled: Bool, file: StaticString = #filePath, line: UInt = #line) -> Self {
		let toggle = immersiveModeSwitch(file: file, line: line)
		let predicate = NSPredicate(format: "value == %@", enabled ? "1" : "0")
		let expectation = XCTNSPredicateExpectation(predicate: predicate, object: toggle)
		XCTAssertEqual(
			XCTWaiter.wait(for: [expectation], timeout: 5),
			.completed,
			"Expected immersive mode to be \(enabled ? "enabled" : "disabled").",
			file: file,
			line: line
		)
		return self
	}

	/// Changes the preference only when the switch does not already show the requested state.
	@MainActor
	@discardableResult
	func setImmersiveModeEnabled(_ enabled: Bool, file: StaticString = #filePath, line: UInt = #line) -> Self {
		let toggle = immersiveModeSwitch(file: file, line: line)
		if toggle.value as? String != (enabled ? "1" : "0") {
			toggle.tap()
		}
		return self
	}

	@MainActor private var settingsView: XCUIElement {
		base.app.otherElements[AccessibilityIdentifiers.Settings.view]
	}

	/// Uses a bounded scroll to reach the row on smaller screens and larger text sizes.
	@MainActor
	private func immersiveModeSwitch(file: StaticString, line: UInt) -> XCUIElement {
		let toggle = base.app.switches[AccessibilityIdentifiers.Settings.immersiveModeSwitch]
		for _ in 0..<8 {
			if toggle.exists && toggle.isHittable { break }
			settingsView.swipeUp()
		}
		base.assertVisible(toggle, description: "immersive mode switch", file: file, line: line)
		return toggle
	}
}
