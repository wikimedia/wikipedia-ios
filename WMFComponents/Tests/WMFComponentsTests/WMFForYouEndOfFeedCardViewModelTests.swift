import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

/// Covers the end of feed card: its variant and analytics identity, its once-per-feed impression,
/// the inputs the feed view uses to decide between the end of feed empty state and the settings
/// empty state, and the wiring of its actions through `WMFHomeViewModel`.
@MainActor
final class WMFForYouEndOfFeedCardViewModelTests: XCTestCase {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func article(_ title: String) -> WMFForYouArticle {
        WMFForYouArticle(title: title, project: project)
    }

    private func emptyResponse() -> WMFForYouResponse {
        WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        )
    }

    private func responseWithContent() -> WMFForYouResponse {
        WMFForYouResponse(
            interestTopicRandomArticles: [
                WMFForYouInterestTopicRandomArticles(topic: .architecture, articles: [article("A1")])
            ],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: WMFForYouBecauseYouReadArticles(recentlyRead: article("Read"), articles: [article("B1")]),
            continueReadingArticles: WMFForYouContinueReading(continueReadingArticle: article("C1"), fromReadingListArticles: [])
        )
    }

    private func makeHomeViewModel() -> WMFHomeViewModel {
        WMFHomeViewModel(dataController: WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore()))
    }

    // MARK: - Variant

    /// The feed decides the card's variant once, when it is built: a feed with no pages at all uses
    /// the card as its empty state; otherwise the card is the last page of the feed. The variant
    /// carries the analytics identity, so the two states can be told apart in the data.
    func testVariantFollowsFeedContent() {
        let emptyFeed = WMFForYouViewModel(response: emptyResponse())
        XCTAssertEqual(emptyFeed.endOfFeedViewModel.variant, .emptyFeed)
        XCTAssertEqual(emptyFeed.endOfFeedViewModel.loggingId, "feed_empty")

        let fullFeed = WMFForYouViewModel(response: responseWithContent())
        XCTAssertEqual(fullFeed.endOfFeedViewModel.variant, .endOfFeed)
        XCTAssertEqual(fullFeed.endOfFeedViewModel.loggingId, "end_of_feed")
    }

    // MARK: - Impression

    /// The impression ends the home_feed funnel, so it must fire exactly once however often the
    /// reader lands back on the card within the same feed.
    func testImpressionReportsOnlyOnce() {
        let endOfFeed = WMFForYouEndOfFeedCardViewModel()
        var impressions = 0
        endOfFeed.onShow = { impressions += 1 }

        endOfFeed.reportShownIfNeeded()
        endOfFeed.reportShownIfNeeded()
        endOfFeed.reportShownIfNeeded()

        XCTAssertEqual(impressions, 1)
    }

    /// A refresh builds a new `WMFForYouViewModel`, and with it a new end of feed card. The new
    /// feed is a new digest, so its card must be able to log its own impression.
    func testEachFeedGetsItsOwnImpression() {
        var impressions = 0

        let firstFeed = WMFForYouViewModel(response: responseWithContent())
        firstFeed.endOfFeedViewModel.onShow = { impressions += 1 }
        firstFeed.endOfFeedViewModel.reportShownIfNeeded()
        firstFeed.endOfFeedViewModel.reportShownIfNeeded()

        let refreshedFeed = WMFForYouViewModel(response: responseWithContent())
        refreshedFeed.endOfFeedViewModel.onShow = { impressions += 1 }
        refreshedFeed.endOfFeedViewModel.reportShownIfNeeded()

        XCTAssertEqual(impressions, 2)
    }

    // MARK: - Empty state routing inputs

    /// The feed view shows the end of feed card as the empty state when `pages` is empty: no
    /// personalized content exists at all (no interests, no reading history).
    func testEmptyResponseBuildsNoPages() {
        let viewModel = WMFForYouViewModel(response: emptyResponse())
        XCTAssertTrue(viewModel.pages.isEmpty)
    }

    /// Turning every module off must not empty `pages`: the pages stay built and only their
    /// visibility changes. The feed view relies on this to show the settings empty state (which
    /// offers turning modules back on) instead of the end of feed card.
    func testTurningModulesOffKeepsPagesBuilt() {
        let viewModel = WMFForYouViewModel(
            response: responseWithContent(),
            moduleVisibility: WMFForYouModuleVisibility(basedOnInterests: false, becauseYouRead: false, continueReading: false)
        )

        XCTAssertFalse(viewModel.pages.isEmpty)
        for page in viewModel.pages {
            XCTAssertFalse(viewModel.moduleVisibility.isVisible(page.module))
        }
    }

    /// Hiding every card must not empty `pages` either, for the same reason.
    func testHidingEveryCardKeepsPagesBuilt() {
        let viewModel = WMFForYouViewModel(response: responseWithContent())
        viewModel.hiddenCardKeys = Set(viewModel.pages.flatMap { $0.articleViewModels.map(\.cardUniqueKey) })

        XCTAssertFalse(viewModel.pages.isEmpty)
    }

    // MARK: - Home view model wiring

    func testTappingCommunitySwitchesTabAndLogsAsEndOfFeed() {
        let homeViewModel = makeHomeViewModel()
        homeViewModel.selectedTab = .forYou

        var loggedSource: String?
        homeViewModel.logEndOfFeedDidTapCommunity = { loggedSource = $0 }

        homeViewModel.forYouViewModel = WMFForYouViewModel(response: responseWithContent())
        homeViewModel.forYouViewModel?.endOfFeedViewModel.onTapCommunity?()

        XCTAssertEqual(homeViewModel.selectedTab, .community)
        XCTAssertEqual(loggedSource, "end_of_feed")
    }

    func testTappingAddInterestsOpensInterestsAndLogsAsEndOfFeed() {
        let homeViewModel = makeHomeViewModel()

        var loggedSource: String?
        var loggedElement: String?
        var didOpenInterests = false
        homeViewModel.logDidTapCustomizeInterests = { source, element in
            loggedSource = source
            loggedElement = element
        }
        homeViewModel.didTapCustomizeInterests = { didOpenInterests = true }

        homeViewModel.forYouViewModel = WMFForYouViewModel(response: responseWithContent())
        homeViewModel.forYouViewModel?.endOfFeedViewModel.onTapAddInterests?()

        XCTAssertTrue(didOpenInterests)
        XCTAssertEqual(loggedSource, "end_of_feed")
        XCTAssertEqual(loggedElement, "customize_feed")
    }

    /// The same tap on the empty feed variant must log as the empty feed.
    func testTappingAddInterestsOnEmptyFeedLogsAsEmptyFeed() {
        let homeViewModel = makeHomeViewModel()

        var loggedSource: String?
        homeViewModel.logDidTapCustomizeInterests = { source, _ in loggedSource = source }

        homeViewModel.forYouViewModel = WMFForYouViewModel(response: emptyResponse())
        homeViewModel.forYouViewModel?.endOfFeedViewModel.onTapAddInterests?()

        XCTAssertEqual(loggedSource, "feed_empty")
    }

    func testImpressionReachesTheLogClosureWithTheVariantSource() {
        let homeViewModel = makeHomeViewModel()

        var loggedSources: [String] = []
        homeViewModel.logEndOfFeedImpression = { loggedSources.append($0) }

        homeViewModel.forYouViewModel = WMFForYouViewModel(response: responseWithContent())
        homeViewModel.forYouViewModel?.endOfFeedViewModel.reportShownIfNeeded()
        homeViewModel.forYouViewModel?.endOfFeedViewModel.reportShownIfNeeded()

        XCTAssertEqual(loggedSources, ["end_of_feed"])
    }
}
