import XCTest
import WMFComponents

/// Tests for the new multi-step app onboarding, shown at first launch when the home tab
/// feature flag is enabled. The legacy welcome flow (shown when the flag is off) is covered
/// by `AppOnboardingUITests`.
final class NewAppOnboardingUITests: XCTestCase {

    func testFirstLaunchShowsOnboardingSmoke() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: true)
            .newOnboarding
            .assertPage(.intro)
    }

    func testLegacyOnboardingShownWhenHomeTabDisabled() throws {
        let app = launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: false)

        app.onboarding
            .assertPage(.introduction)
        app.newOnboarding
            .assertNotShown()
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

        let app = launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: true)

        app.newOnboarding
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
        launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: true)
            .newOnboarding
            .advance(to: .feedPreference)
            .tapNext()
            .assertDismissed()
    }

    func testSkipFromPersonalizationCompletesOnboarding() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: true)
            .newOnboarding
            .advance(to: .personalizationIntro)
            .tapSkip()
            .assertDismissed()
    }

    func testLearnMoreLinksPresentDestinations() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: true)
            .newOnboarding
            .assertPage(.intro)
            .assertLearnMoreOpensWebView()
            .advance(to: .dataPrivacy)
            .assertPrivacyAndTermsLinksExist()
    }

    func testAdditionalLanguageCanBeAddedDuringOnboarding() throws {
        let app = launchWikipediaAppRobot(
            onboardingState: .notCompleted,
            resetsPreferredLanguages: true,
            enablesHomeTab: true
        )

        let preferredLanguages = app.newOnboarding
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
            resetsPreferredLanguages: true,
            enablesHomeTab: true
        )
            .newOnboarding
            .advance(to: .languages)
            .openPreferredLanguages()
            .assertPreferredLanguage(expectedLanguageCode)
    }

    func testInterestsSearchAddsArticle() throws {
        launchWikipediaAppRobot(onboardingState: .notCompleted, enablesHomeTab: true)
            .newOnboarding
            .advance(to: .interests)
            .searchInterests(for: "Einstein")
            .addFirstSearchResult()
            .assertHasSelections()
    }
}
