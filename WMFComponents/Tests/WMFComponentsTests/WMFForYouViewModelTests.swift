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
}
