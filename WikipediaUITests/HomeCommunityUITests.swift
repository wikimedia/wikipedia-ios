import XCTest

/// Tests for the native Community feed of the Home tab, shown while Home phase 2 is on.
final class HomeCommunityUITests: XCTestCase {

    func testCommunityFeedShowsTodaySmoke() throws {
        openCommunity()
            .assertFeedVisible()
            .assertTodayHeaderVisible()
            .assertModuleVisible(.topRead)
    }

    func testFeaturedArticleOpensArticle() throws {
        try skipInE2E("The featured article changes every day on live wikis.")

        openCommunity()
            .assertModuleVisible(.featuredArticle)
            .openFeaturedArticle()
            .assertLoadedArticle(named: fixture.featuredArticleTitle)
    }

    func testFeaturedArticleSaveForLaterSavesAndUnsaves() throws {
        try skipInE2E("The featured article changes every day on live wikis.")
        let title = fixture.featuredArticleTitle
        let app = launchApp()

        app.home
            .assertVisible()
            .openCommunity()
            .tapSaveForLater()
        app.home
            .openSaved()
            .assertArticleRowVisible(title)

        app.home
            .tapRootTab(.home)
            .openCommunity()
            .tapSaveForLater()
        app.home
            .openSaved()
            .assertArticleRowAbsent(title)
    }

    func testTopReadRowOpensArticle() throws {
        try skipInE2E("The Top read list changes every day on live wikis.")

        openCommunity()
            .assertTopReadRowsVisible()
            .openTopReadRow(titled: fixture.featuredArticleTitle)
            .assertLoadedArticle(named: fixture.featuredArticleTitle)
    }

    func testMoreTopReadOpensTopReadList() throws {
        openCommunity()
            .assertModuleVisible(.topRead)
            .tapMoreTopRead()
            .goBackToHome()
    }

    func testInTheNewsCarouselSwipesAndOpensStory() throws {
        try skipInE2E("The number of In the news stories changes on live wikis.")

        openCommunity()
            .assertModuleVisible(.inTheNews)
            .assertNewsStoryPage(1, of: HomeFeedFixture.newsStoryCount)
            .swipeToNextNewsStory()
            .assertNewsStoryPage(2, of: HomeFeedFixture.newsStoryCount)
            .openNewsStory()
            .goBackToHome()
    }

    func testOnThisDayOpensEventsFromMoreLinkAndEvent() throws {
        try skipInE2E("Relies on the bundled feed fixture to know which wikis have On this day.")

        let feed = openCommunity()
        guard fixture.hasOnThisDay else {
            // The Hebrew and Vietnamese wikis have no On this day, so their feed leaves the module out.
            feed.assertFeedVisible()
                .assertModuleVisible(.topRead)
                .assertModuleAbsent(.onThisDay)
            return
        }

        feed.assertModuleVisible(.onThisDay)
            .tapMoreOnThisDay()
            .goBackToHome()
            .openCommunity()
            .openOnThisDayEvent()
            .goBackToHome()
    }

    func testPictureOfTheDayOpensGallery() throws {
        openCommunity()
            .assertModuleVisible(.pictureOfTheDay)
            .openPictureOfTheDay()
    }

    func testSeePastContentLoadsEarlierDay() throws {
        openCommunity()
            .assertFeedVisible()
            .assertDateHeaderCount(atLeast: 1)
            .tapSeePastContent()
            .assertDateHeaderCount(atLeast: 2)
    }

    func testHideCardFromModuleMenuRemovesModuleCard() throws {
        try skipInE2E("Hidden cards depend on the featured article of the day.")

        openCommunity()
            .assertModuleVisible(.featuredArticle)
            .tapModuleMenuItem(.hideCard, in: .featuredArticle)
            .assertModuleAbsent(.featuredArticle)
            .assertModuleVisible(.topRead)
    }

    func testHideModuleFromModuleMenuRemovesModule() throws {
        openCommunity()
            .assertModuleVisible(.topRead)
            .tapModuleMenuItem(.hideModule, in: .topRead)
            .assertModuleAbsent(.topRead)
    }

    func testHidingEveryModuleShowsEmptyStateThatOpensSettings() throws {
        try skipInE2E("Relies on the bundled feed fixture to know which modules the day has.")

        var feed = openCommunity().assertFeedVisible()
        for module in [CommunityFeedRobot.Module.featuredArticle, .topRead, .inTheNews, .pictureOfTheDay] {
            feed = feed.tapModuleMenuItem(.hideModule, in: module)
        }
        guard fixture.hasOnThisDay else {
            // The Hebrew and Vietnamese wikis have no On this day, so its module cannot be hidden from
            // the feed and stays on in settings. The empty state needs every module off, so the day
            // shows no module and only the "See past community content" button.
            feed.assertSeePastContentVisible()
            return
        }

        feed.tapModuleMenuItem(.hideModule, in: .onThisDay)
            .assertEmptyStateVisible()
            .tapEmptyStateCustomize()
    }

    func testCustomizeCommunityFeedFromModuleMenuOpensFeedSettings() throws {
        openCommunity()
            .assertModuleVisible(.topRead)
            .tapCustomizeCommunityFeed(in: .topRead)
            .goBackToHome()
    }

    func testCommunityErrorStateRetryLoadsFeed() throws {
        try skipInE2E("The offline requests only apply to fixture-backed networking.")

        // Today and yesterday load at the same time, so both requests fail once.
        let featuredFeedRequest = UITestOfflineRequest(
            host: "\(uiTestConfiguration.languageCode).wikipedia.org",
            pathPrefix: "/api/rest_v1/feed/featured/",
            count: 2
        )

        // Home loads the selected feed again when the WMFData store finishes opening after launch.
        // That second load would spend the failures before the test sees the error, so the test
        // opens on For You and goes to Community after the For You feed shows, when the store is open.
        launchApp(homeFeedState: UITestHomeFeedState(seeFirst: .personalized), offlineRequests: [featuredFeedRequest])
            .home
            .assertVisible()
            .assertSegmentSelected(.forYou)
            .openForYou()
            .assertEndOfFeedVisible()
            .home
            .openCommunity()
            .assertErrorVisible()
            .tapRetry()
            .assertFeedVisible()
            .assertTodayHeaderVisible()
    }

    // MARK: - Helpers

    private var fixture: HomeFeedFixture {
        guard let fixture = HomeFeedFixture.fixture(languageCode: uiTestConfiguration.languageCode) else {
            preconditionFailure("HomeCommunityUITests requires a supported Home feed fixture language.")
        }
        return fixture
    }

    private func launchApp(
        homeFeedState: UITestHomeFeedState = .noInterests,
        offlineRequests: [UITestOfflineRequest] = []
    ) -> WikipediaAppRobot {
        launchWikipediaAppRobot(
            onboardingState: .completed,
            readingListsSeed: .empty,
            homePhase: .phase2,
            homeFeedState: homeFeedState,
            offlineRequests: offlineRequests
        )
    }

    private func openCommunity(
        offlineRequests: [UITestOfflineRequest] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CommunityFeedRobot {
        launchApp(offlineRequests: offlineRequests)
            .home
            .assertVisible(file: file, line: line)
            .openCommunity(file: file, line: line)
    }
}
