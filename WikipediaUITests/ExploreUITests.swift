import XCTest

final class ExploreUITests: XCTestCase {
    func testExplore() throws {
        enum ScreenshotNames: String {
            case initial = "Explore Initial"
            case profile = "Explore Profile"
        }
        
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .captureScreenshot(ScreenshotNames.initial)
            .openProfile()
            .captureScreenshot(ScreenshotNames.profile)
    }

    func testExploreTopTabsButtonOpensArticleTabs() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openTabs()
    }

    func testExploreTopProfileButtonOpensProfile() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openProfile()
    }

    func testExploreBottomTabsCanBeTapped() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .tapRootTab(.explore)
            .tapRootTab(.places)
            .tapRootTab(.saved)
            .tapRootTab(.activity)
            .tapRootTab(.search)
    }

    func testExploreBottomTabsExposeAccessibilityIdentifiers() throws {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .assertRootTabAccessibilityIdentifiersSurfaced()
    }

    func testExploreSearchShowsResult() throws {
        let searchTerm = exploreSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTermOneCharacterAtATime(searchTerm)
            .assertSearchResultVisible(named: searchTerm)
    }

    func testExploreSearchResultStaysVisibleAfterRotation() throws {
        let searchTerm = exploreSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
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

    func testExploreSearchResultOpensArticle() throws {
        let searchTerm = exploreSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTermOneCharacterAtATime(searchTerm)
            .assertSearchResultVisible(named: searchTerm)
            .openResult(named: searchTerm)
            .assertVisible()
            .assertTopControlsVisible()
    }

    func testExploreRecentSearchesCanBeCleared() throws {
        let searchTerm = exploreSearchTerm

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
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

    private var exploreSearchTerm: String {
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
            preconditionFailure("Explore search tests unsupported search fixture language")
        }
    }
}
