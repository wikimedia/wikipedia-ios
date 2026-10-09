import XCTest

final class HomeUITests: XCTestCase {
	/// The preference applies immediately, survives launch, and covers both native and article screens.
	@MainActor
	func testImmersiveModePersistsAndRestoresStatusBar() throws {
		try XCTSkipUnless(
			uiTestConfiguration.httpClientProfile == TestHTTPClientProfile.fixtureStrict.rawValue,
			"Immersive mode coverage uses bundled article fixtures."
		)
		guard let fixture = ArticleRobot.articleControlsFixture(languageCode: uiTestConfiguration.languageCode) else {
			throw XCTSkip("Immersive mode coverage requires an article fixture for the configured language.")
		}

		let app = launchWikipediaAppRobot(onboardingState: .completed)
		app.home
			.rotateToPortrait()
			.assertVisible()
			.openProfile()
			.openSettings()
			.setImmersiveModeEnabled(false)
			.assertImmersiveModeEnabled(false)
			.assertStatusBarVisible()
			.setImmersiveModeEnabled(true)
			.assertImmersiveModeEnabled(true)
			.assertStatusBarHidden()

		app.relaunch()
			.home
			.assertVisible()
			.assertStatusBarHidden()
			.openSearch()
			.focusSearchField()
			.typeSearchTerm(fixture.primaryArticleTitle)
			.assertSearchResultVisible(named: fixture.primaryArticleTitle)
			.openResult(named: fixture.primaryArticleTitle)
			.assertVisible()
			.assertTopControlsVisible()
			.assertStatusBarHidden()
			.tapHomeButtonToHome()
			.openProfile()
			.openSettings()
			.assertImmersiveModeEnabled(true)
			.setImmersiveModeEnabled(false)
			.assertImmersiveModeEnabled(false)
			.assertStatusBarVisible()
	}

    func testHome() throws {
        enum ScreenshotNames: String {
            case initial = "Home Initial"
            case profile = "Home Profile"
        }
        
        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .captureScreenshot(ScreenshotNames.initial)
            .openProfile()
            .captureScreenshot(ScreenshotNames.profile)
    }

    func testHomeTopTabsButtonOpensArticleTabs() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .openTabs()
    }

    func testHomeTopProfileButtonOpensProfile() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .openProfile()
    }

    func testHomeBottomTabsCanBeTapped() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .tapRootTab(.home)
            .tapRootTab(.places)
            .tapRootTab(.saved)
            .tapRootTab(.activity)
            .tapRootTab(.search)
    }

    func testHomeBottomTabsExposeAccessibilityIdentifiers() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .assertRootTabAccessibilityIdentifiersSurfaced()
    }

    func testHomeSearchShowsResult() throws {
        let searchTerm = homeSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTermOneCharacterAtATime(searchTerm)
            .assertSearchResultVisible(named: searchTerm)
    }

    func testHomeSearchResultStaysVisibleAfterRotation() throws {
        let searchTerm = homeSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTermOneCharacterAtATime(searchTerm)
            .assertSearchResultVisible(named: searchTerm)
            .rotateToLandscapeLeft()
            .assertSearchFieldVisible(description: "search field after rotation")
            .rotateToPortrait()
            .assertSearchFieldVisible(description: "search field after returning to portrait")
            .assertSearchResultVisible(named: searchTerm)
    }

    func testHomeSearchResultOpensArticle() throws {
        let searchTerm = homeSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTermOneCharacterAtATime(searchTerm)
            .assertSearchResultVisible(named: searchTerm)
            .openResult(named: searchTerm)
            .assertVisible()
            .assertTopControlsVisible()
    }

    func testHomeRecentSearchesCanBeCleared() throws {
        let searchTerm = homeSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTermOneCharacterAtATime(searchTerm)
            .assertSearchResultVisible(named: searchTerm)
            .openResult(named: searchTerm)
            .assertVisible()
            .assertTopControlsVisible()
            .tapSearch()
            .focusSearchField()
            .assertRecentSearchTermVisible(searchTerm)
            .tapClearRecentSearches()
            .confirmClearRecentSearches()
            .assertRecentSearchTermCleared(searchTerm)
    }

    private var homeSearchTerm: String {
        switch uiTestConfiguration.languageCode {
        case "en":
            "Dog"
        case "de":
            "Haushund"
        case "he":
            "כלב הבית"
        case "vi":
            "Chó"
        default:
            preconditionFailure("Home search tests unsupported search fixture language")
        }
    }
}
