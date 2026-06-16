import XCTest
import WMFComponents

/// Drives the all-languages picker shown after a user chooses to add another app language.
struct AllLanguagesRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
}

// MARK: - Screen state

extension AllLanguagesRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.LanguageSelection.allLanguagesView],
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Content

extension AllLanguagesRobot {
    @discardableResult
    func search(for languageCode: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let searchField = base.app.searchFields.firstMatch
        base.assertExists(searchField, file: file, line: line)
        searchField.tap()
        searchField.typeText(languageCode)
        return self
    }
}

// MARK: - Navigation

extension AllLanguagesRobot {
    @discardableResult
    func selectLanguage(_ languageCode: String, file: StaticString = #filePath, line: UInt = #line) -> PreferredLanguagesRobot {
        let languageCell = base.app.cells[AccessibilityIdentifiers.LanguageSelection.allLanguage(languageCode)]
        base.assertExists(languageCell, file: file, line: line)
        languageCell.tap()
        return PreferredLanguagesRobot(base: base).assertPreferredLanguage(languageCode, file: file, line: line)
    }
}
