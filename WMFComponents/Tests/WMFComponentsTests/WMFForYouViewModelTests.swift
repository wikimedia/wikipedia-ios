import XCTest
@testable import WMFComponents
@testable import WMFData

/// Covers how the feed is assembled from a response: the order the modules appear in, and which
/// module keeps an article when more than one offers it.
final class WMFForYouViewModelTests: XCTestCase {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func article(_ title: String) -> WMFForYouArticle {
        WMFForYouArticle(title: title, project: project)
    }

    private func interestPage(_ topic: WMFArticleTopic, _ titles: [String]) -> WMFForYouInterestTopicRandomArticles {
        WMFForYouInterestTopicRandomArticles(topic: topic, articles: titles.map(article))
    }

    @MainActor
    private func titles(of page: WMFForYouPageViewModel) -> [String] {
        page.articleViewModels.map { $0.title }
    }

    // MARK: - Module order

    @MainActor
    func testFirstThreeInterestPagesComeBeforeTheOtherModules() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [
                interestPage(.architecture, ["A1"]),
                interestPage(.biography, ["A2"]),
                interestPage(.biology, ["A3"]),
                interestPage(.history, ["A4"]),
                interestPage(.mathematics, ["A5"])
            ],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: WMFForYouBecauseYouReadArticles(recentlyRead: article("Read"), articles: [article("B1")]),
            continueReadingArticles: WMFForYouContinueReading(continueReadingArticle: article("C1"), savedArticles: [])
        )

        let viewModel = WMFForYouViewModel(response: response)

        XCTAssertEqual(viewModel.pages.map { $0.module }, [
            .basedOnInterests, .basedOnInterests, .basedOnInterests,
            .becauseYouRead,
            .continueReading,
            .basedOnInterests, .basedOnInterests
        ])
    }

    @MainActor
    func testModulesWithNoContentAreLeftOut() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [interestPage(.architecture, ["A1"])],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        )

        let viewModel = WMFForYouViewModel(response: response)

        XCTAssertEqual(viewModel.pages.map { $0.module }, [.basedOnInterests])
    }

    // MARK: - Deduplication

    @MainActor
    func testAnArticleIsNotRepeatedAcrossModules() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [interestPage(.architecture, ["Shared", "OnlyInterest"])],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: WMFForYouBecauseYouReadArticles(recentlyRead: article("Read"), articles: [article("Shared"), article("OnlyBecauseYouRead")]),
            continueReadingArticles: nil
        )

        let viewModel = WMFForYouViewModel(response: response)

        XCTAssertEqual(titles(of: viewModel.pages[0]), ["Shared", "OnlyInterest"])
        XCTAssertEqual(titles(of: viewModel.pages[1]), ["OnlyBecauseYouRead"], "The interest page is built first, so it keeps the shared article")
    }

    @MainActor
    func testAnArticleIsNotRepeatedWithinOneModule() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [interestPage(.architecture, ["Dup", "Dup", "Other"])],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        )

        let viewModel = WMFForYouViewModel(response: response)

        XCTAssertEqual(titles(of: viewModel.pages[0]), ["Dup", "Other"])
    }

    @MainActor
    func testTheContinueReadingArticleIsNotRepeatedAmongTheSavedArticles() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: WMFForYouContinueReading(
                continueReadingArticle: article("Current"),
                savedArticles: [article("Current"), article("Saved")]
            )
        )

        let viewModel = WMFForYouViewModel(response: response)

        XCTAssertEqual(titles(of: viewModel.pages[0]), ["Current", "Saved"])
    }

    // MARK: - Accessibility

    @MainActor
    func testHeaderLabelResolvesItsPlaceholderForVoiceOver() {
        let header = WMFForYouHeaderLabel(format: "Because you read: %1$@", highlight: "Octopus")

        XCTAssertEqual(header.accessibilityText, "Because you read: Octopus", "A reader needs the whole sentence, not the format string")
    }

    @MainActor
    func testCardAccessibilityLabelReadsWhyThenWhat() {
        let article = WMFForYouArticle(title: "Octopus", project: project)
        let header = WMFForYouHeaderLabel(format: "Because of your interest: %1$@", highlight: "Biology")
        let card = WMFForYouArticleCardViewModel(article: article, headerLabel: header)
        card.extract = "An octopus is a soft-bodied mollusc."

        XCTAssertEqual(card.accessibilityLabel, "Because of your interest: Biology, Octopus, An octopus is a soft-bodied mollusc.")
    }

    @MainActor
    func testCardAccessibilityLabelFallsBackToTheDescription() {
        let article = WMFForYouArticle(title: "Octopus", project: project)
        let header = WMFForYouHeaderLabel(format: "Because you read: %1$@", highlight: "Squid")
        let card = WMFForYouArticleCardViewModel(article: article, headerLabel: header)
        card.description = "Marine animal"
        card.extract = nil

        XCTAssertEqual(card.accessibilityLabel, "Because you read: Squid, Octopus, Marine animal")
    }

    // MARK: - Position in the feed

    @MainActor
    private func twoModuleViewModel() -> WMFForYouViewModel {
        WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [
                interestPage(.biology, ["A1", "A2"]),
                interestPage(.history, ["B1", "B2"])
            ],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))
    }

    @MainActor
    func testFeedStartsWithNoRememberedPosition() {
        let viewModel = twoModuleViewModel()

        XCTAssertNil(viewModel.lastViewedModuleID)
        XCTAssertNil(viewModel.lastViewedCardKey)
    }

    @MainActor
    func testViewedModuleIsRemembered() {
        let viewModel = twoModuleViewModel()
        let secondModuleID = viewModel.pages[1].id

        viewModel.rememberViewedModule(secondModuleID)

        XCTAssertEqual(viewModel.lastViewedModuleID, secondModuleID)
    }

    @MainActor
    func testViewedCardIsRemembered() {
        let viewModel = twoModuleViewModel()
        let card = viewModel.pages[1].articleViewModels[0].cardUniqueKey

        viewModel.rememberViewedCard(card)

        XCTAssertEqual(viewModel.lastViewedCardKey, card)
    }

    @MainActor
    private func cardKeys(of viewModel: WMFForYouViewModel) -> [String] {
        viewModel.pages.flatMap { $0.articleViewModels.map { $0.cardUniqueKey } }
    }

    /// The remembered card carries no module of its own, so every card that goes through the
    /// deduplicator must have its own key. If two cards shared a key, a second module could restore
    /// the position to the same article.
    @MainActor
    func testCardKeysAreUniqueAcrossDeduplicatedModules() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [
                interestPage(.biology, ["Shared", "A2"]),
                interestPage(.history, ["Shared", "B2"])
            ],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: WMFForYouBecauseYouReadArticles(recentlyRead: article("Read"), articles: [article("Shared"), article("C1")]),
            continueReadingArticles: WMFForYouContinueReading(continueReadingArticle: article("Continue"), savedArticles: [article("Shared"), article("D1")])
        )

        let keys = cardKeys(of: WMFForYouViewModel(response: response))

        XCTAssertEqual(keys.count, Set(keys).count)
    }

    /// Known gap, not a decision: the continue reading card does not go through the deduplicator, so
    /// the same article can also be in an earlier module. T427673 says that duplicate articles must
    /// not be in different modules on the same day. Which module keeps the article is a product
    /// decision, so this test records the behaviour of today.
    @MainActor
    func testContinueReadingCardCanRepeatAnArticleFromAnEarlierModule() {
        let response = WMFForYouResponse(
            interestTopicRandomArticles: [interestPage(.biology, ["Shared", "A2"])],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: WMFForYouContinueReading(continueReadingArticle: article("Shared"), savedArticles: [])
        )

        let keys = cardKeys(of: WMFForYouViewModel(response: response))

        XCTAssertEqual(keys.count - Set(keys).count, 1)
    }

    /// A new feed must start at the top, so the position must not come across from the old view model.
    @MainActor
    func testANewFeedHasNoRememberedPosition() {
        let viewModel = twoModuleViewModel()
        viewModel.rememberViewedModule(viewModel.pages[1].id)

        let newViewModel = twoModuleViewModel()

        XCTAssertNil(newViewModel.lastViewedModuleID)
    }
}
