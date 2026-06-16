import XCTest
import WMFComponents

/// Represents the preferred-languages screen reached from onboarding language setup.
struct PreferredLanguagesRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private static let preferredLanguageIdentifierPrefix =
        AccessibilityIdentifiers.LanguageSelection.preferredLanguage("")
}

// MARK: - Screen state

extension PreferredLanguagesRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let preferredLanguageCell = base.app.cells.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", Self.preferredLanguageIdentifierPrefix)
        ).firstMatch
        base.assertExists(preferredLanguageCell, file: file, line: line)
        return self
    }

    @discardableResult
    func assertPreferredLanguage(_ languageCode: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let preferredLanguageCell = base.app.cells[AccessibilityIdentifiers.LanguageSelection.preferredLanguage(languageCode)]
        base.assertExists(preferredLanguageCell, file: file, line: line)
        return self
    }
}

// MARK: - Content

extension PreferredLanguagesRobot {
    func languageCodeAvailableToAdd() throws -> String {
        let candidateLanguageCodes = ["es", "fr", "it", "ja", "pt", "ar"]

        guard let languageCode = candidateLanguageCodes.first(where: { languageCode in
            !base.app.cells[AccessibilityIdentifiers.LanguageSelection.preferredLanguage(languageCode)].exists
        }) else {
            throw XCTSkip("No candidate language was available to add.")
        }

        return languageCode
    }
}

// MARK: - Navigation

extension PreferredLanguagesRobot {
    @discardableResult
    func tapAddLanguage(file: StaticString = #filePath, line: UInt = #line) -> AllLanguagesRobot {
        let button = base.app.buttons.matching(
            identifier: AccessibilityIdentifiers.LanguageSelection.preferredLanguagesAddLanguageButton
        ).firstMatch

        if !button.waitForExistence(timeout: 2) {
            for _ in 0..<4 where !button.exists {
                base.app.swipeUp()
            }
        }

        base.assertExists(button, file: file, line: line)
        button.tap()
        return AllLanguagesRobot(base: base).assertVisible(file: file, line: line)
    }
}
