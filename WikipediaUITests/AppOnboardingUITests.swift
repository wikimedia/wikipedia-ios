import XCTest
import WMFComponents

final class AppOnboardingUITests: XCTestCase {

    func testFirstLaunchShowsOnboardingSmoke() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.introduction)
    }

    func testOnboardingScreenshots() throws {
        enum ScreenshotNames: String {
            case analytics = "App Onboarding Analytics"
            case exploration = "App Onboarding Exploration"
            case initial = "App Onboarding Initial"
            case languages = "App Onboarding Languages"
        }

        let app = launchWikipediaAppRobot(onboardingState: .notCompleted)

        app.onboarding
            .assertPage(.introduction)
            .captureScreenshot(ScreenshotNames.initial)
            .tapNext()
            .assertPage(.exploration)
            .captureScreenshot(ScreenshotNames.exploration)
            .tapNext()
            .assertPage(.languages)
            .captureScreenshot(ScreenshotNames.languages)
            .tapNext()
            .assertPage(.analytics)
            .captureScreenshot(ScreenshotNames.analytics)
    }

    func testLearnMoreLinksPresentDestinations() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.introduction)
            .assertIntroductionLearnMoreCanBeDismissed()
            .advance(to: .analytics)
            .assertAnalyticsLearnMoreDestinationsCanBePresented()
    }

    func testAdditionalLanguageCanBeAddedDuringOnboarding() throws {
        let app = launchWikipediaAppRobot(
            onboardingState: .notCompleted,
            resetsPreferredLanguages: true
        )

        let preferredLanguages = app.onboarding
            .advance(to: .languages)
            .openPreferredLanguages()
        let targetLanguageCode = try preferredLanguages.languageCodeAvailableToAdd()

        preferredLanguages
            .tapAddLanguage()
            .search(for: targetLanguageCode)
            .selectLanguage(targetLanguageCode)
    }

    func testLaunchLocaleSeedsPreferredWikipediaLanguage() throws {
        let expectedLanguageCode = uiTestConfiguration.languageCode

        launchWikipediaAppRobot(
            onboardingState: .notCompleted,
            resetsPreferredLanguages: true
    )
            .onboarding
            .advance(to: .languages)
            .openPreferredLanguages()
            .assertPreferredLanguage(expectedLanguageCode)
    }

    func testWelcomeScreensCanBeAdvancedByTappingNext() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.introduction)
            .tapNext()
            .assertPage(.exploration)
            .tapNext()
            .assertPage(.languages)
            .tapNext()
            .assertPage(.analytics)
    }

    func testWelcomeScreensCanBeAdvancedBySwiping() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.introduction)
            .swipeToNextPage(from: .introduction, to: .exploration)
            .swipeToNextPage(from: .exploration, to: .languages)
            .swipeToNextPage(from: .languages, to: .analytics)
    }

    func testOnboardingCanBeSkipped() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.introduction)
            .skipToExplore()
    }
}
