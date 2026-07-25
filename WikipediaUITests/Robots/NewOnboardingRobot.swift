import XCTest
import WMFComponents

/// Drives the new first-launch app onboarding flow (shown when the home tab feature flag is
/// enabled): step advancement, learn-more web views, language setup, interests selection,
/// and skip behavior.
struct NewOnboardingRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }
}

// MARK: - Page types

extension NewOnboardingRobot {
    enum OnboardingPage: CaseIterable {
        case intro
        case dataPrivacy
        case languages
        case personalizationIntro
        case interests
        case feedPreference

        var accessibilityIdentifier: String {
            switch self {
            case .intro:
                return AccessibilityIdentifiers.Onboarding.introView
            case .dataPrivacy:
                return AccessibilityIdentifiers.Onboarding.dataPrivacyView
            case .languages:
                return AccessibilityIdentifiers.Onboarding.languagesView
            case .personalizationIntro:
                return AccessibilityIdentifiers.Onboarding.personalizationIntroView
            case .interests:
                return AccessibilityIdentifiers.Interests.view
            case .feedPreference:
                return AccessibilityIdentifiers.Onboarding.feedPreferenceView
            }
        }
    }
}

// MARK: - Screen state

extension NewOnboardingRobot {
    /// Steps are SwiftUI views whose root container can surface as different element types
    /// (e.g. a single-child stack collapses onto its ScrollView), so match any element type.
    private func pageElement(_ page: OnboardingPage) -> XCUIElement {
        base.app.descendants(matching: .any)[page.accessibilityIdentifier]
    }

    @discardableResult
    func assertPage(_ page: OnboardingPage, file: StaticString = #filePath, line: UInt = #line) -> Self {
        // Generous timeout: the first page can take a while to appear on a cold install
        // while app data migration runs.
        base.assertExists(
            pageElement(page),
            timeout: 30,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertNotShown(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(pageElement(.intro).exists, "New onboarding should not be shown", file: file, line: line)
        return self
    }

    @discardableResult
    func assertDismissed(file: StaticString = #filePath, line: UInt = #line) -> Self {
        for page in OnboardingPage.allCases {
            base.waitForElementToDisappear(
                pageElement(page),
                timeout: 10,
                file: file,
                line: line
            )
        }
        base.assertExists(base.app.tabBars.firstMatch, timeout: 10, file: file, line: line)
        return self
    }
}

// MARK: - Navigation

extension NewOnboardingRobot {
    @discardableResult
    func advance(to targetPage: OnboardingPage, file: StaticString = #filePath, line: UInt = #line) -> Self {
        guard let targetIndex = OnboardingPage.allCases.firstIndex(of: targetPage) else {
            XCTFail("Unknown onboarding page", file: file, line: line)
            return self
        }

        assertPage(.intro, file: file, line: line)
        guard targetIndex > 0 else {
            return self
        }

        for page in OnboardingPage.allCases[1...targetIndex] {
            tapNext(file: file, line: line)
            assertPage(page, file: file, line: line)
        }

        return self
    }

    @discardableResult
    func tapNext(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.nextButton,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func tapSkip(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.skipButton,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func openPreferredLanguages(file: StaticString = #filePath, line: UInt = #line) -> PreferredLanguagesRobot {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.addLanguagesButton,
            file: file,
            line: line
        )
        return PreferredLanguagesRobot(base: base).assertVisible(file: file, line: line)
    }
}

// MARK: - Web view links

extension NewOnboardingRobot {
    @discardableResult
    func assertLearnMoreOpensWebView(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.learnMoreLink,
            file: file,
            line: line
        )

        let webView = base.app.webViews.firstMatch
        base.assertExists(webView, timeout: 15, file: file, line: line)

        let closeButton = base.app.navigationBars.firstMatch.buttons.firstMatch
        base.assertExists(closeButton, file: file, line: line)
        closeButton.tap()
        base.waitForElementToDisappear(webView, timeout: 10, file: file, line: line)
        return self
    }

    /// The privacy policy and terms of use links are AttributedString ranges inside a single
    /// SwiftUI Text, which XCUITest exposes as one StaticText without tappable Link children —
    /// so assert their presence rather than tapping the individual ranges. Their tap handling
    /// presents the same in-app web view as the intro's learn-more button, which is tapped.
    @discardableResult
    func assertPrivacyAndTermsLinksExist(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.descendants(matching: .any)[AccessibilityIdentifiers.Onboarding.privacyLinks],
            timeout: 10,
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Interests

extension NewOnboardingRobot {
    @discardableResult
    func searchInterests(for term: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let searchField = base.app.textFields[AccessibilityIdentifiers.Interests.searchField]
        base.assertExists(searchField, timeout: 10, file: file, line: line)
        searchField.tap()
        searchField.typeText(term)
        return self
    }

    @discardableResult
    func addFirstSearchResult(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let firstResult = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Interests.searchResultRow)
            .firstMatch
        base.assertExists(firstResult, timeout: 10, file: file, line: line)
        firstResult.tap()
        return self
    }

    @discardableResult
    func assertHasSelections(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.buttons[AccessibilityIdentifiers.Interests.deselectAllButton],
            timeout: 10,
            file: file,
            line: line
        )
        return self
    }
}
