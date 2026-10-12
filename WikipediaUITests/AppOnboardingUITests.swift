import XCTest
import WMFComponents

/// Tests for the app onboarding shown at first launch.
final class AppOnboardingUITests: XCTestCase {

    func testFirstLaunchShowsOnboardingSmoke() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.intro)
    }

    func testOnboardingScreenshots() throws {
        enum ScreenshotNames: String {
            case intro = "App Onboarding Intro"
            case dataPrivacy = "App Onboarding Data Privacy"
            case languages = "App Onboarding Languages"
            case personalizationIntro = "App Onboarding Personalization Intro"
            case interests = "App Onboarding Interests"
            case feedPreference = "App Onboarding Feed Preference"
        }

        let app = launchWikipediaAppRobot(onboardingState: .notCompleted)

        app.onboarding
            .assertPage(.intro)
            .captureScreenshot(ScreenshotNames.intro)
            .tapNext()
            .assertPage(.dataPrivacy)
            .captureScreenshot(ScreenshotNames.dataPrivacy)
            .tapNext()
            .assertPage(.languages)
            .captureScreenshot(ScreenshotNames.languages)
            .tapNext()
            .assertPage(.personalizationIntro)
            .captureScreenshot(ScreenshotNames.personalizationIntro)
            .tapNext()
            .assertPage(.interests)
            .captureScreenshot(ScreenshotNames.interests)
            .tapNext()
            .assertPage(.feedPreference)
            .captureScreenshot(ScreenshotNames.feedPreference)
    }

    func testAdvanceThroughAllStepsCompletesOnboarding() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .advance(to: .feedPreference)
            .tapNext()
            .assertDismissed()
    }

    func testSkipFromPersonalizationCompletesOnboarding() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .advance(to: .personalizationIntro)
            .tapSkip()
            .assertDismissed()
    }

    func testLearnMoreLinksPresentDestinations() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .assertPage(.intro)
            .assertLearnMoreOpensWebView()
            .advance(to: .dataPrivacy)
            .assertPrivacyAndTermsLinksExist()
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

    func testInterestsSearchAddsArticle() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .advance(to: .interests)
            .searchInterests(for: "Einstein")
            .addFirstSearchResult()
            .assertHasSelections()
    }
}
