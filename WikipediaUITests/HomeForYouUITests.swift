import XCTest

/// Tests for the For You segment of the Home tab.
final class HomeForYouUITests: XCTestCase {

    func testForYouFeedShowsCardsSmoke() throws {
        openForYou()
            .assertFeedVisible()
    }

    func testForYouCardOpensArticle() throws {
        try skipInE2E("Opens a card that only the bundled topic search fixture is guaranteed to have.")

        openForYou()
            .assertFeedVisible()
            .openCard(titled: HomeFeedFixture.firstForYouCardTitle)
            .assertTopControlsVisible()
    }

    func testForYouCardCanBeSavedAndUnsavedFromItsMenu() throws {
        try skipInE2E("Saves a card that only the bundled topic search fixture is guaranteed to have.")
        let title = HomeFeedFixture.firstForYouCardTitle

        openForYou()
            .assertFeedVisible()
            .assertCardNotSaved(titled: title)
            .tapMenuItem(.save, forCardTitled: title)
            .assertCardSaved(titled: title)
            .tapMenuItem(.unsave, forCardTitled: title)
            .assertCardNotSaved(titled: title)
    }

    func testForYouCardShareOpensShareSheet() throws {
        try skipInE2E("Shares a card that only the bundled topic search fixture is guaranteed to have.")

        openForYou()
            .assertFeedVisible()
            .tapMenuItem(.share, forCardTitled: HomeFeedFixture.firstForYouCardTitle)
            .assertShareSheetVisible()
            .dismissShareSheet()
            .assertCardVisible(titled: HomeFeedFixture.firstForYouCardTitle)
    }

    func testForYouHideCardRemovesOnlyThatCard() throws {
        try skipInE2E("Hides a card that only the bundled topic search fixture is guaranteed to have.")

        openForYou()
            .assertFeedVisible()
            .tapMenuItem(.hideCard, forCardTitled: HomeFeedFixture.firstForYouCardTitle)
            .assertCardAbsent(titled: HomeFeedFixture.firstForYouCardTitle)
            .assertCardVisible(titled: HomeFeedFixture.secondForYouCardTitle)
    }

    func testForYouHideModuleShowsEmptyStateThatOpensFeedSettings() throws {
        try skipInE2E("Relies on the bundled topic search fixture to give the feed exactly one module.")

        openForYou()
            .assertFeedVisible()
            .tapMenuItem(.hideModule, forCardTitled: HomeFeedFixture.firstForYouCardTitle)
            .assertEmptyStateVisible()
            .tapEmptyStateCustomize()
    }

    func testForYouCardMenuCustomizeInterestsOpensInterests() throws {
        try skipInE2E("Opens the menu of a card that only the bundled topic search fixture is guaranteed to have.")

        openForYou()
            .assertFeedVisible()
            .tapCustomizeInterests(forCardTitled: HomeFeedFixture.firstForYouCardTitle)
    }

    func testForYouErrorStateRetryLoadsFeed() throws {
        try skipInE2E("The offline requests only apply to fixture-backed networking.")

        openForYou(offlineRequests: [topicSearchRequest(count: 1)])
            .assertErrorVisible()
            .tapRetry()
            .assertFeedVisible()
            .assertCardVisible(titled: HomeFeedFixture.firstForYouCardTitle)
    }

    func testForYouEndOfFeedCardSwitchesToCommunity() throws {
        try skipInE2E("Relies on the bundled topic search fixture to give the feed exactly one module.")

        openForYou(homePhase: .phase2)
            .assertFeedVisible()
            .scrollToEndOfFeed()
            .tapEndOfFeedCommunity()
            .assertSegmentSelected(.community)
            .openCommunity()
            .assertFeedVisible()
    }

    func testForYouWithoutInterestsShowsEndOfFeedCard() throws {
        openForYou(homeFeedState: .noInterests)
            .assertEndOfFeedVisible()
    }

    // MARK: - Helpers

    private func openForYou(
        homePhase: UITestConfiguration.HomePhase = .phase1,
        homeFeedState: UITestHomeFeedState = .oneInterest,
        offlineRequests: [UITestOfflineRequest] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ForYouFeedRobot {
        // The empty reading-lists seed removes saved articles, which add a "From your reading list" module.
        launchWikipediaAppRobot(
            onboardingState: .completed,
            readingListsSeed: .empty,
            homePhase: homePhase,
            homeFeedState: homeFeedState,
            offlineRequests: offlineRequests
        )
        .home
        .assertVisible(file: file, line: line)
        .openForYou(file: file, line: line)
    }

    /// The topic search of the interest module, the one request the For You feed makes for it.
    private func topicSearchRequest(count: Int) -> UITestOfflineRequest {
        UITestOfflineRequest(
            host: "\(uiTestConfiguration.languageCode).wikipedia.org",
            path: "/w/api.php",
            queryItems: ["generator": "search", "gsrsort": "random"],
            count: count
        )
    }
}
