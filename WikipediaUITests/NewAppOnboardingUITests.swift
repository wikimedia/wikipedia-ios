import XCTest
import WMFComponents

/// Tests for the app onboarding shown at first launch.
final class NewAppOnboardingUITests: XCTestCase {

    func testFirstLaunchShowsOnboardingSmoke() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .Onboarding
            .assertPage(.intro)
    }

    func testOnboardingScreenshots() throws {
        enum ScreenshotNames: String {
            case intro = "New App Onboarding Intro"
            case dataPrivacy = "New App Onboarding Data Privacy"
            case languages = "New App Onboarding Languages"
            case personalizationIntro = "New App Onboarding Personalization Intro"
            case interests = "New App Onboarding Interests"
            case feedPreference = "New App Onboarding Feed Preference"
        }

        let app = launchWikipediaAppRobot(onboardingState: .notCompleted)

        app.Onboarding
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
            .Onboarding
            .advance(to: .feedPreference)
            .tapNext()
            .assertDismissed()
    }

    func testSkipFromPersonalizationCompletesOnboarding() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .Onboarding
            .advance(to: .personalizationIntro)
            .tapSkip()
            .assertDismissed()
    }

    func testLearnMoreLinksPresentDestinations() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .Onboarding
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

        let preferredLanguages = app.Onboarding
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
            .Onboarding
            .advance(to: .languages)
            .openPreferredLanguages()
            .assertPreferredLanguage(expectedLanguageCode)
    }

    func testInterestsSearchAddsArticle() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .Onboarding
            .advance(to: .interests)
            .searchInterests(for: "Einstein")
            .addFirstSearchResult()
            .assertHasSelections()
    }
}
