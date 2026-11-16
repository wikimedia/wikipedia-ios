import XCTest
import WMFComponents

/// Drives the Settings screen and the Home feed settings screens it leads to, down to the
/// "Your interests" screen. Each step waits for its row and returns the next screen's robot.
struct SettingsRobot: ScreenshotCapturingRobot {
    let base: UITestRobot

    private func row(_ identifier: String) -> XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func tapRow(_ identifier: String, file: StaticString, line: UInt) {
        let row = row(identifier)
        base.assertVisible(row, timeout: 15, file: file, line: line)
        row.tap()
    }
}

// MARK: - Screen state

extension SettingsRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(row(AccessibilityIdentifiers.Settings.homeFeedRow), timeout: 15, file: file, line: line)
        return self
    }
}

// MARK: - Home feed settings

extension SettingsRobot {
    /// Opens "Customize the home feed" from Settings.
    @discardableResult
    func openHomeFeedSettings(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapRow(AccessibilityIdentifiers.Settings.homeFeedRow, file: file, line: line)
        base.assertExists(row(AccessibilityIdentifiers.HomeFeedSettings.whatsDrivingRow), timeout: 15, file: file, line: line)
        return self
    }

    /// Opens "What's driving your feed" from "Customize the home feed".
    @discardableResult
    func openWhatsDriving(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapRow(AccessibilityIdentifiers.HomeFeedSettings.whatsDrivingRow, file: file, line: line)
        base.assertExists(row(AccessibilityIdentifiers.HomeFeedSettings.yourInterestsRow), timeout: 15, file: file, line: line)
        return self
    }

    /// Pushes "Your interests" from "What's driving your feed".
    @discardableResult
    func openYourInterests(file: StaticString = #filePath, line: UInt = #line) -> InterestsRobot {
        tapRow(AccessibilityIdentifiers.HomeFeedSettings.yourInterestsRow, file: file, line: line)
        return InterestsRobot(base: base).assertVisible(file: file, line: line)
    }

    /// Pops back to "What's driving your feed" from "Your interests".
    @discardableResult
    func goBackToWhatsDriving(isRightToLeft: Bool, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let navigationBar = base.app.navigationBars.firstMatch
        base.assertExists(navigationBar, file: file, line: line)
        base.backButton(in: navigationBar, isRightToLeft: isRightToLeft).tap()
        base.assertExists(row(AccessibilityIdentifiers.HomeFeedSettings.yourInterestsRow), timeout: 15, file: file, line: line)
        return self
    }
}
