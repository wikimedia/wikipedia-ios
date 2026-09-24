import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite
struct WMFAppOnboardingFeedPreferenceViewModelTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    private let spanishLanguage = WMFLanguage(languageCode: "es", languageVariantCode: nil)

    private func makeViewModel() -> WMFAppOnboardingFeedPreferenceViewModel {
        let dataController = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
        return WMFAppOnboardingFeedPreferenceViewModel(dataController: dataController, project: project, logImpression: {_ in }, logDidTapCommunity: {}, logDidTapPersonalized: {})
    }

    private func makeArticle(_ title: String) -> WMFForYouArticle {
        WMFForYouArticle(title: title, project: project)
    }

    private func makeForYouResponse(
        topicArticles: [WMFForYouInterestTopicRandomArticles] = [],
        pageArticles: [WMFForYouInterestPageRelatedArticles] = [],
        becauseYouRead: WMFForYouBecauseYouReadArticles? = nil,
        continueReading: WMFForYouContinueReading? = nil
    ) -> WMFForYouResponse {
        WMFForYouResponse(
            interestTopicRandomArticles: topicArticles,
            interestPageRelatedArticles: pageArticles,
            becauseYouReadArticles: becauseYouRead,
            continueReadingArticles: continueReading
        )
    }

    // MARK: - Selection

    @Test
    func selectionDefaultsToCommunity() {
        let viewModel = makeViewModel()
        #expect(viewModel.selection == .community)
    }

    @Test
    func selectPersonalizedUpdatesSelection() {
        let viewModel = makeViewModel()
        viewModel.select(.personalized)
        #expect(viewModel.selection == .personalized)
        viewModel.select(.community)
        #expect(viewModel.selection == .community)
    }

    @Test
    func resetSelectionAppliesDefault() {
        let viewModel = makeViewModel()
        viewModel.select(.personalized)
        viewModel.resetSelectionToDefault()
        #expect(viewModel.selection == .community)
    }

    @Test
    func personalizedIsNotSelectableWhileLoading() {
        let viewModel = makeViewModel()
        viewModel.isPersonalizedLoading = true
        viewModel.select(.personalized)
        #expect(viewModel.selection == .community)

        viewModel.isPersonalizedLoading = false
        viewModel.select(.personalized)
        #expect(viewModel.selection == .personalized)
    }

    @Test
    func communityIsAlwaysSelectableWhileLoading() {
        let viewModel = makeViewModel()
        viewModel.isPersonalizedLoading = false
        viewModel.select(.personalized)
        viewModel.isPersonalizedLoading = true
        viewModel.select(.community)
        #expect(viewModel.selection == .community)
    }

    @Test
    func updateProjectFollowsPrimaryLanguageChange() {
        let viewModel = makeViewModel()
        let spanishProject = WMFProject.wikipedia(spanishLanguage)
        viewModel.updateProject(spanishProject)
        #expect(viewModel.project == spanishProject)
    }

    // MARK: - Availability

    @Test
    func personalizedAvailableWithInterestTopics() {
        let response = makeForYouResponse(topicArticles: [
            WMFForYouInterestTopicRandomArticles(topic: .music, articles: [makeArticle("A")])
        ])
        #expect(WMFAppOnboardingFeedPreferenceViewModel.personalizedIsAvailable(for: response) == true)
    }

    @Test
    func personalizedUnavailableWithReadingHistoryOnly() {
        // Reading history isn't something the user chose here, so it can't stand in for
        // interests — the step shows its explanation text instead.
        let response = makeForYouResponse(
            becauseYouRead: WMFForYouBecauseYouReadArticles(recentlyRead: makeArticle("Read"), articles: [makeArticle("A")]),
            continueReading: nil
        )
        #expect(WMFAppOnboardingFeedPreferenceViewModel.personalizedIsAvailable(for: response) == false)
    }

    @Test
    func personalizedUnavailableWithoutInterestsOrHistory() {
        let response = makeForYouResponse()
        #expect(WMFAppOnboardingFeedPreferenceViewModel.personalizedIsAvailable(for: response) == false)
    }

    // MARK: - Personalized cards

    @Test
    func personalizedCardsComeFromFirstThreeInterestTopicsWithPills() {
        let response = makeForYouResponse(topicArticles: [
            WMFForYouInterestTopicRandomArticles(topic: .music, articles: [makeArticle("Music article")]),
            WMFForYouInterestTopicRandomArticles(topic: .architecture, articles: [makeArticle("Architecture article")]),
            WMFForYouInterestTopicRandomArticles(topic: .education, articles: [makeArticle("Education article")]),
            WMFForYouInterestTopicRandomArticles(topic: .foodAndDrink, articles: [makeArticle("Food article")])
        ])

        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: response)
        #expect(cards.count == 3)
        #expect(cards[0].displayTitle == "Music article")
        #expect(cards[0].topicPill == WMFArticleTopic.music.displayName)
        #expect(cards.allSatisfy { $0.topicPill != nil })
    }

    @Test
    func personalizedCardsIgnoreReadingHistory() {
        // Without chosen interests there are no cards at all — reading-history articles read
        // as random in this preview, so they must not fill in.
        let response = makeForYouResponse(
            becauseYouRead: WMFForYouBecauseYouReadArticles(
                recentlyRead: makeArticle("Read"),
                articles: [makeArticle("A"), makeArticle("B"), makeArticle("C"), makeArticle("D")]
            )
        )

        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: response)
        #expect(cards.isEmpty)
    }

    @Test
    func personalizedCardsFillFromPageInterestsAfterTopics() {
        let response = makeForYouResponse(
            topicArticles: [
                WMFForYouInterestTopicRandomArticles(topic: .music, articles: [makeArticle("Music article")])
            ],
            pageArticles: [
                WMFForYouInterestPageRelatedArticles(pageInterest: makeArticle("Page interest"), articles: [makeArticle("Related article")])
            ]
        )

        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: response)
        #expect(cards.count == 2)
        #expect(cards[0].topicPill == WMFArticleTopic.music.displayName)
        #expect(cards[1].displayTitle == "Related article")
        #expect(cards[1].topicPill == nil)
    }

    @Test
    func personalizedCardsEmptyWithoutInterestsOrHistory() {
        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: makeForYouResponse())
        #expect(cards.isEmpty)
    }

    // MARK: - Community cards

    @Test
    func featuredArticleCardKeepsItsMarkedUpDisplayTitle() throws {
        // The wiki italicizes film and book titles, and the card renders HTML, so the markup has
        // to survive rather than being flattened to the normalized title.
        let json = """
        {
            "tfa": {
                "title": "The_Macomber_Affair",
                "normalizedtitle": "The Macomber Affair",
                "displaytitle": "<i>The Macomber Affair</i>"
            }
        }
        """
        let feedResponse = try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(json.utf8))
        let response = WMFCommunityResponse(date: Date(), feedResponse: feedResponse, onThisDay: nil)

        let cards = makeViewModel().buildCommunityCards(from: response)

        #expect(cards.first?.displayTitle == "<i>The Macomber Affair</i>")
    }

    @Test
    func communityCardsBuildFromFeedResponse() throws {
        let json = """
        {
            "tfa": {
                "title": "Featured_Article",
                "normalizedtitle": "Featured Article",
                "description": "A featured thing",
                "thumbnail": { "source": "https://example.org/fa.jpg", "width": 100, "height": 100 }
            },
            "image": {
                "title": "File:Picture.jpg",
                "thumbnail": { "source": "https://example.org/potd.jpg", "width": 100, "height": 100 },
                "description": { "text": "A pretty picture", "html": "<p>A pretty picture</p>", "lang": "en" }
            },
            "news": [
                {
                    "story": "Something <b>happened</b> today",
                    "links": [ { "title": "Event", "thumbnail": { "source": "https://example.org/news.jpg", "width": 100, "height": 100 } } ]
                }
            ]
        }
        """
        let feedResponse = try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(json.utf8))
        let response = WMFCommunityResponse(date: Date(), feedResponse: feedResponse, onThisDay: nil)

        let viewModel = makeViewModel()
        let cards = viewModel.buildCommunityCards(from: response)

        #expect(cards.count == 3)
        #expect(cards[0].displayTitle == "Featured Article")
        #expect(cards[0].description == "A featured thing")
        #expect(cards[1].description == "A pretty picture")
        // News story HTML is stripped
        #expect(cards[2].description == "Something happened today")
        #expect(cards.allSatisfy { $0.topicPill == nil })
    }

    @Test
    func communityCardsSkipMissingModules() throws {
        let feedResponse = try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data("{}".utf8))
        let response = WMFCommunityResponse(date: Date(), feedResponse: feedResponse, onThisDay: nil)

        let viewModel = makeViewModel()
        #expect(viewModel.buildCommunityCards(from: response).isEmpty)
    }

    // MARK: - Summary cache keys

    /// The summary cache uses the exact title string as its key. The cards, the warm-up, and the
    /// For You feed cards must all use the display form, so one fetch serves all of them.
    @Test
    func personalizedCardsFetchSummariesWithTheDisplayTitleForm() async {
        let summaryController = MockArticleSummaryDataController()
        let response = makeForYouResponse(topicArticles: [
            WMFForYouInterestTopicRandomArticles(topic: .biology, articles: [makeArticle("Giant_squid")])
        ])

        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: response, summaryDataController: summaryController)
        for card in cards {
            await card.loadSummaryIfNeeded()
        }

        #expect(await summaryController.requestedTitles == ["Giant squid"])
    }

    /// The search response already carries the description and the thumbnail. A card built from
    /// that metadata is complete at once and must not fetch the summary.
    @Test
    func personalizedCardsWithResponseMetadataSkipTheSummaryFetch() async {
        let summaryController = MockArticleSummaryDataController()
        let article = WMFForYouArticle(
            title: "Giant_squid",
            project: project,
            description: "Deep-sea squid",
            thumbnailURL: URL(string: "https://example.org/squid.jpg")
        )
        let response = makeForYouResponse(topicArticles: [
            WMFForYouInterestTopicRandomArticles(topic: .biology, articles: [article])
        ])

        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: response, summaryDataController: summaryController)
        for card in cards {
            await card.loadSummaryIfNeeded()
        }

        #expect(await summaryController.requestedTitles.isEmpty, "The metadata is already in hand, so no summary fetch is necessary")
        #expect(cards.first?.description == "Deep-sea squid")
    }
}

/// The warm-up tests share the process-wide `WMFDataEnvironment` and a temporary Core Data
/// store, so they run one at a time - the same rule as the other fixture-based suites.
@Suite(.serialized)
@MainActor
final class WMFAppOnboardingFeedPreferenceWarmUpTests {

    private let fixture = WMFDataTestFixture()
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    private func configureEnvironmentWithoutCoreDataStore() async throws {
        WMFDataEnvironment.current.coreDataStore = nil
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    /// A view model whose For You fetch runs against mocks, with a service that counts requests.
    private func makeCountingViewModel() -> (WMFAppOnboardingFeedPreferenceViewModel, CountingBasicService, MockArticleSummaryDataController) {
        let service = CountingBasicService()
        let homeController = WMFHomeDataController(
            feedDataController: WMFMockFeedDataController(response: WMFFeedAPIResponse(todaysFeaturedArticle: nil, mostRead: nil, image: nil, news: nil)),
            basicService: service,
            userDefaultsStore: WMFMockKeyValueStore(),
            relatedPagesDataController: WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get")),
            savedArticlesDataController: WMFSavedArticlesDataController(),
            onThisDayDataController: WMFOnThisDayDataController(basicService: WMFMockServiceNoInternetConnection())
        )
        homeController.setInterestTopics([.biology])
        let summaryController = MockArticleSummaryDataController()
        let viewModel = WMFAppOnboardingFeedPreferenceViewModel(
            dataController: homeController,
            summaryDataController: summaryController,
            project: project,
            logImpression: { _ in },
            logDidTapCommunity: {},
            logDidTapPersonalized: {}
        )
        return (viewModel, service, summaryController)
    }

    /// The core promise: the article download starts while the user is on the interests step,
    /// and the fetch on the feed preference step reads the result instead of the network.
    @Test
    func theFeedPreviewReusesTheWarmedArticles() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let (viewModel, service, summaryController) = makeCountingViewModel()

            viewModel.interestsDidChange(topics: [.biology], selectedArticleTitles: [])
            await viewModel.waitForWarmUp()
            #expect(service.decodableGETCallCount == 1)

            viewModel.loadIfNeeded()
            await viewModel.waitForLoadTasks()

            #expect(service.decodableGETCallCount == 1, "The preview must reuse the warmed articles, not fetch them again")
            #expect(viewModel.personalizedCards.count == 1)
            #expect(viewModel.isPersonalizedAvailable)
            #expect(viewModel.isPersonalizedLoading == false)
            // The search response carried the card content, so the reveal costs no further requests.
            #expect(await summaryController.requestedTitles.isEmpty)
        }
    }

    @Test
    func repeatedChangesDownloadEachInterestOneTime() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let (viewModel, service, _) = makeCountingViewModel()

            viewModel.interestsDidChange(topics: [.biology], selectedArticleTitles: [])
            await viewModel.waitForWarmUp()
            viewModel.interestsDidChange(topics: [.biology], selectedArticleTitles: [])
            await viewModel.waitForWarmUp()

            #expect(service.decodableGETCallCount == 1, "A fresh warmed group must not be fetched again")
        }
    }

    @Test
    func theFeedPreviewFetchesOnceWithoutAWarmUp() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let (viewModel, service, _) = makeCountingViewModel()

            viewModel.loadIfNeeded()
            await viewModel.waitForLoadTasks()

            #expect(service.decodableGETCallCount == 1)
            #expect(viewModel.personalizedCards.count == 1)
        }
    }

    @Test
    func aFailedFetchDoesNotBlockTheFeedPreview() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithoutCoreDataStore) {
            let (viewModel, _, _) = makeCountingViewModel()

            viewModel.interestsDidChange(topics: [.biology], selectedArticleTitles: [])
            await viewModel.waitForWarmUp()
            viewModel.loadIfNeeded()
            await viewModel.waitForLoadTasks()

            #expect(viewModel.personalizedCards.isEmpty)
            #expect(viewModel.isPersonalizedLoading == false)
            #expect(viewModel.isPersonalizedAvailable, "One topic is selected, so the option stays available")
        }
    }
}

/// Counts the requests that reach the service. The responses come from the standard mock.
private final class CountingBasicService: WMFService, @unchecked Sendable {
    private let wrapped = WMFMockBasicService(jsonResourceName: "random-articles-get")
    private let lock = NSLock()
    private var _decodableGETCallCount = 0

    var decodableGETCallCount: Int {
        lock.withLock { _decodableGETCallCount }
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        wrapped.perform(request: request, completion: completion)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        wrapped.perform(request: request, completion: completion)
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        lock.withLock { _decodableGETCallCount += 1 }
        wrapped.performDecodableGET(request: request, completion: completion)
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        wrapped.performDecodablePOST(request: request, completion: completion)
    }

    func clearCachedData() {}
}
