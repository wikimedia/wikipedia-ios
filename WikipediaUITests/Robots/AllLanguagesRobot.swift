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
        // On a slow runner the first tap can land before the field accepts focus, and typing then fails.
        if !waitForKeyboardFocus(searchField, timeout: 5) {
            searchField.tap()
            XCTAssertTrue(
                waitForKeyboardFocus(searchField, timeout: 10),
                "Expected the language search field to have keyboard focus.",
                file: file,
                line: line
            )
        }
        searchField.typeText(languageCode)
        return self
    }

    private func waitForKeyboardFocus(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}

// MARK: - Navigation

extension AllLanguagesRobot {
    @discardableResult
    func selectLanguage(_ languageCode: String, file: StaticString = #filePath, line: UInt = #line) -> PreferredLanguagesRobot {
        let languageCell = base.app.cells[AccessibilityIdentifiers.LanguageSelection.allLanguage(languageCode)]
        base.assertExists(languageCell, timeout: 10, file: file, line: line)
        languageCell.tap()
        return PreferredLanguagesRobot(base: base).assertPreferredLanguage(languageCode, file: file, line: line)
    }
}
