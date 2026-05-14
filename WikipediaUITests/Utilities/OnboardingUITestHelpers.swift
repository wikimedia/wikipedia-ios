import XCTest
import WMFComponents

enum OnboardingPage: CaseIterable {
    case introduction
    case exploration
    case languages
    case analytics

    var accessibilityIdentifier: String {
        switch self {
        case .introduction:
            return AccessibilityIdentifiers.Onboarding.introductionView
        case .exploration:
            return AccessibilityIdentifiers.Onboarding.explorationView
        case .languages:
            return AccessibilityIdentifiers.Onboarding.languagesView
        case .analytics:
            return AccessibilityIdentifiers.Onboarding.analyticsView
        }
    }
}

extension XCTestCase {
    func assertOnboardingPage(_ page: OnboardingPage, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.otherElements[page.accessibilityIdentifier].waitForExistence(timeout: 5), file: file, line: line)
    }

    func advanceOnboarding(to targetPage: OnboardingPage, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        guard let targetIndex = OnboardingPage.allCases.firstIndex(of: targetPage) else {
            XCTFail("Unknown onboarding page", file: file, line: line)
            return
        }

        assertOnboardingPage(.introduction, in: app, file: file, line: line)
        guard targetIndex > 0 else {
            return
        }

        for page in OnboardingPage.allCases[1...targetIndex] {
            tapOnboardingNext(in: app, file: file, line: line)
            assertOnboardingPage(page, in: app, file: file, line: line)
        }
    }

    func tapOnboardingNext(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        tapButton(withIdentifier: AccessibilityIdentifiers.Onboarding.nextButton, in: app, file: file, line: line)
    }

    func tapPreferredLanguagesAddLanguageButton(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons.matching(identifier: AccessibilityIdentifiers.LanguageSelection.preferredLanguagesAddLanguageButton).firstMatch
        if !button.waitForExistence(timeout: 2) {
            for _ in 0..<4 where !button.exists {
                app.swipeUp()
            }
        }

        XCTAssertTrue(button.waitForExistence(timeout: 5), file: file, line: line)
        button.tap()
    }

    func waitForPreferredLanguagesList(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let preferredLanguageCell = app.cells.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "Language Selection Preferred Language ")
        ).firstMatch
        XCTAssertTrue(preferredLanguageCell.waitForExistence(timeout: 5), file: file, line: line)
    }

    func swipeToNextOnboardingPage(from currentPage: OnboardingPage, to nextPage: OnboardingPage, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let currentElement = app.otherElements[currentPage.accessibilityIdentifier]
        XCTAssertTrue(currentElement.waitForExistence(timeout: 5), file: file, line: line)

        if uiTestConfiguration.isRightToLeft {
            currentElement.swipeRight()
        } else {
            currentElement.swipeLeft()
        }

        assertOnboardingPage(nextPage, in: app, file: file, line: line)
    }

    func languageCodeAvailableToAdd(in app: XCUIApplication) throws -> String {
        let candidateLanguageCodes = ["es", "fr", "it", "ja", "pt", "ar"]

        guard let languageCode = candidateLanguageCodes.first(where: { languageCode in
            !app.cells[AccessibilityIdentifiers.LanguageSelection.preferredLanguage(languageCode)].exists
        }) else {
            throw XCTSkip("No candidate language was available to add.")
        }

        return languageCode
    }
}
