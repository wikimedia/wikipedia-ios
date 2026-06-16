import XCTest
import WMFComponents

/// Drives the first-launch onboarding flow, including paging, learn-more modals, language setup, and skip behavior.
struct OnboardingRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }
}

// MARK: - Page types

extension OnboardingRobot {
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
}

// MARK: - Screen state

extension OnboardingRobot {
    @discardableResult
    func assertPage(_ page: OnboardingPage, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[page.accessibilityIdentifier],
            timeout: 10,
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Navigation

extension OnboardingRobot {
    @discardableResult
    func advance(to targetPage: OnboardingPage, file: StaticString = #filePath, line: UInt = #line) -> Self {
        guard let targetIndex = OnboardingPage.allCases.firstIndex(of: targetPage) else {
            XCTFail("Unknown onboarding page", file: file, line: line)
            return self
        }

        assertPage(.introduction, file: file, line: line)
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
    func swipeToNextPage(
        from currentPage: OnboardingPage,
        to nextPage: OnboardingPage,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let currentElement = base.app.otherElements[currentPage.accessibilityIdentifier]
        base.assertVisible(currentElement, file: file, line: line)

        if configuration.isRightToLeft {
            currentElement.swipeRight()
        } else {
            currentElement.swipeLeft()
        }

        base.waitForElementToDisappear(currentElement, timeout: 10, file: file, line: line)
        assertPage(nextPage, file: file, line: line)
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

    @discardableResult
    func skipToExplore(file: StaticString = #filePath, line: UInt = #line) -> ExploreRobot {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.skipButton,
            file: file,
            line: line
        )
        return ExploreRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }
}

// MARK: - Content

extension OnboardingRobot {
    @discardableResult
    func assertIntroductionLearnMoreCanBeDismissed(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.introductionLearnMoreButton,
            file: file,
            line: line
        )

        let alert = base.app.alerts.firstMatch
        base.assertExists(alert, file: file, line: line)
        alert.buttons.firstMatch.tap()
        base.waitForElementToDisappear(alert, file: file, line: line)
        return self
    }

    @discardableResult
    func assertAnalyticsLearnMoreDestinationsCanBePresented(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Onboarding.analyticsLearnMoreButton,
            file: file,
            line: line
        )

        let analyticsLinks = base.app.sheets.firstMatch
        base.assertExists(analyticsLinks, file: file, line: line)
        base.assertExists(analyticsLinks.buttons.element(boundBy: 0), file: file, line: line)
        base.assertExists(analyticsLinks.buttons.element(boundBy: 1), file: file, line: line)
        base.assertExists(analyticsLinks.buttons.element(boundBy: 2), file: file, line: line)
        analyticsLinks.buttons.element(boundBy: 2).tap()
        return self
    }
}
