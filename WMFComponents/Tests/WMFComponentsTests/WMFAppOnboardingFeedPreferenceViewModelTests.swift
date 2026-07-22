import Foundation
import Testing
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
        return WMFAppOnboardingFeedPreferenceViewModel(dataController: dataController, project: project)
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
    func personalizedAvailableWithReadingHistoryOnly() {
        let response = makeForYouResponse(
            becauseYouRead: WMFForYouBecauseYouReadArticles(recentlyRead: makeArticle("Read"), articles: [makeArticle("A")])
        )
        #expect(WMFAppOnboardingFeedPreferenceViewModel.personalizedIsAvailable(for: response) == true)
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
        #expect(cards[0].title == "Music article")
        #expect(cards[0].topicPill == WMFArticleTopic.music.displayName)
        #expect(cards.allSatisfy { $0.topicPill != nil })
    }

    @Test
    func personalizedCardsFallBackToReadingHistoryWithoutPills() {
        let response = makeForYouResponse(
            becauseYouRead: WMFForYouBecauseYouReadArticles(
                recentlyRead: makeArticle("Read"),
                articles: [makeArticle("A"), makeArticle("B"), makeArticle("C"), makeArticle("D")]
            )
        )

        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: response)
        #expect(cards.count == 3)
        #expect(cards.allSatisfy { $0.topicPill == nil })
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
        #expect(cards[1].title == "Related article")
        #expect(cards[1].topicPill == nil)
    }

    @Test
    func personalizedCardsEmptyWithoutInterestsOrHistory() {
        let cards = WMFAppOnboardingFeedPreferenceViewModel.buildPersonalizedCards(from: makeForYouResponse())
        #expect(cards.isEmpty)
    }

    // MARK: - Community cards

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
        #expect(cards[0].title == "Featured Article")
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
}
