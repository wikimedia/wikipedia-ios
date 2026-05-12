import XCTest
import WMFComponents

final class AppOnboardingUITests: XCTestCase {

    func testFirstLaunchShowsOnboardingSmoke() throws {
        let app = launchWikipediaApp(onboardingState: .notCompleted)
        assertOnboardingPage(.introduction, in: app)
    }

    func testOnboardingScreenshots() throws {
        enum ScreenshotNames: String {
            case analytics = "App Onboarding Analytics"
            case exploration = "App Onboarding Exploration"
            case explore = "App Onboarding Explore"
            case initial = "App Onboarding Initial"
            case languages = "App Onboarding Languages"
        }

        let app = launchWikipediaApp(onboardingState: .notCompleted)
        
        assertOnboardingPage(.introduction, in: app)
        captureScreenshot(named: ScreenshotNames.initial.rawValue, in: app)

        tapOnboardingNext(in: app)
        assertOnboardingPage(.exploration, in: app)
        captureScreenshot(named: ScreenshotNames.exploration.rawValue, in: app)

        tapOnboardingNext(in: app)
        assertOnboardingPage(.languages, in: app)
        captureScreenshot(named: ScreenshotNames.languages.rawValue, in: app)

        tapOnboardingNext(in: app)
        assertOnboardingPage(.analytics, in: app)
        captureScreenshot(named: ScreenshotNames.analytics.rawValue, in: app)

        app.terminate()

        let skipApp = launchWikipediaApp(onboardingState: .notCompleted)
        assertOnboardingPage(.introduction, in: skipApp)
        tapButton(withIdentifier: AccessibilityIdentifiers.Onboarding.skipButton, in: skipApp)

        let exploreView = skipApp.otherElements[AccessibilityIdentifiers.Explore.view]
        XCTAssertTrue(exploreView.waitForExistence(timeout: 5))
        captureScreenshot(named: ScreenshotNames.explore.rawValue, in: skipApp)
    }

    func testLearnMoreLinksPresentDestinations() throws {
        let app = launchWikipediaApp(onboardingState: .notCompleted)

        assertOnboardingPage(.introduction, in: app)
        tapButton(withIdentifier: AccessibilityIdentifiers.Onboarding.introductionLearnMoreButton, in: app)

        let introductionAlert = app.alerts.firstMatch
        XCTAssertTrue(introductionAlert.waitForExistence(timeout: 5))
        introductionAlert.buttons.firstMatch.tap()
        waitForElementToDisappear(introductionAlert)

        advanceOnboarding(to: .analytics, in: app)
        tapButton(withIdentifier: AccessibilityIdentifiers.Onboarding.analyticsLearnMoreButton, in: app)

        let analyticsLinks = app.sheets.firstMatch
        XCTAssertTrue(analyticsLinks.waitForExistence(timeout: 5))
        XCTAssertTrue(analyticsLinks.buttons.element(boundBy: 0).exists)
        XCTAssertTrue(analyticsLinks.buttons.element(boundBy: 1).exists)
        XCTAssertTrue(analyticsLinks.buttons.element(boundBy: 2).exists)
        analyticsLinks.buttons.element(boundBy: 2).tap()
    }

    func testAdditionalLanguageCanBeAddedDuringOnboarding() throws {
        let app = launchWikipediaApp(
            onboardingState: .notCompleted,
            resetsPreferredLanguages: true
        )

        advanceOnboarding(to: .languages, in: app)
        tapButton(withIdentifier: AccessibilityIdentifiers.Onboarding.addLanguagesButton, in: app)

        waitForPreferredLanguagesList(in: app)
        let targetLanguageCode = try languageCodeAvailableToAdd(in: app)
        tapPreferredLanguagesAddLanguageButton(in: app)

        XCTAssertTrue(app.otherElements[AccessibilityIdentifiers.LanguageSelection.allLanguagesView].waitForExistence(timeout: 5))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(targetLanguageCode)

        let languageCell = app.cells[AccessibilityIdentifiers.LanguageSelection.allLanguage(targetLanguageCode)]
        XCTAssertTrue(languageCell.waitForExistence(timeout: 5))
        languageCell.tap()

        let preferredLanguageCell = app.cells[AccessibilityIdentifiers.LanguageSelection.preferredLanguage(targetLanguageCode)]
        XCTAssertTrue(preferredLanguageCell.waitForExistence(timeout: 5))
    }

    func testWelcomeScreensCanBeAdvancedByTappingNext() throws {
        let app = launchWikipediaApp(onboardingState: .notCompleted)

        assertOnboardingPage(.introduction, in: app)
        tapOnboardingNext(in: app)
        assertOnboardingPage(.exploration, in: app)
        tapOnboardingNext(in: app)
        assertOnboardingPage(.languages, in: app)
        tapOnboardingNext(in: app)
        assertOnboardingPage(.analytics, in: app)
    }

    func testWelcomeScreensCanBeAdvancedBySwiping() throws {
        let app = launchWikipediaApp(onboardingState: .notCompleted)

        assertOnboardingPage(.introduction, in: app)
        swipeToNextOnboardingPage(from: .introduction, to: .exploration, in: app)
        swipeToNextOnboardingPage(from: .exploration, to: .languages, in: app)
        swipeToNextOnboardingPage(from: .languages, to: .analytics, in: app)
    }

    func testOnboardingCanBeSkipped() throws {
        let app = launchWikipediaApp(onboardingState: .notCompleted)

        assertOnboardingPage(.introduction, in: app)
        tapButton(withIdentifier: AccessibilityIdentifiers.Onboarding.skipButton, in: app)

        let exploreView = app.otherElements[AccessibilityIdentifiers.Explore.view]
        XCTAssertTrue(exploreView.waitForExistence(timeout: 5))
    }
}
