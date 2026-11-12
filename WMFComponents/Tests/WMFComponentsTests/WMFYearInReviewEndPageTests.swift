import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class EndLoggingSpy: WMFYearInReviewLoggingDelegate {
    var appeared: [String] = []
    var shared: [String] = []
    var sharedHighlights = 0

    func logYearInReviewIntroDidTapLearnMore() {}
    func logYearInReviewSlideDidAppear(slideLoggingID: String) { appeared.append(slideLoggingID) }
    func logYearInReviewDidTapDone(slideLoggingID: String) {}
    func logYearInReviewDidTapNext(slideLoggingID: String) {}
    func logYearInReviewDidTapDonate(slideLoggingID: String) {}
    func logYearInReviewDidTapShare(slideLoggingID: String) { shared.append(slideLoggingID) }
    func logYearInReviewDidTapShareHighlights() { sharedHighlights += 1 }
}

@MainActor
private final class EndCoordinatorSpy: WMFYearInReviewCoordinating {
    var actions: [WMFYearInReviewAction] = []

    func handleYearInReviewAction(_ action: WMFYearInReviewAction) {
        actions.append(action)
    }
}

@MainActor
@Suite
struct WMFYearInReviewEndPageTests {

    // The view model keeps the logging delegate as a weak reference, so the test keeps the spy.
    private let logging = EndLoggingSpy()

    private static func strings() -> WMFYearInReviewViewModel.LocalizedStrings {
        return WMFYearInReviewViewModel.LocalizedStrings(
            closeButtonAccessibilityLabel: "Close",
            moreButtonAccessibilityLabel: "More",
            shareButtonTitle: "Share",
            shareHighlightsButtonTitle: "Share highlights",
            donateButtonTitle: "Donate",
            learnMoreButtonTitle: "Learn more",
            aboutInsightsButtonTitle: "About your insights",
            shareFeedbackButtonTitle: "Share feedback",
            slideAccessibilityHint: "Swipe up or down with three fingers to change the slide.",
            revealAnswerAccessibilityHint: "Double tap to reveal the answer."
        )
    }

    private func makeViewModel(slideCount: Int = 3, hasEnd: Bool = true, hidesDonate: @escaping () -> Bool = { false }) -> WMFYearInReviewViewModel {
        let slides = (0..<slideCount).map { index in
            WMFYearInReviewSlideViewModel(id: "slide\(index)", loggingID: "logging\(index)")
        }
        let viewModel = WMFYearInReviewViewModel(
            slides: slides,
            localizedStrings: Self.strings(),
            coordinatorDelegate: nil,
            loggingDelegate: logging,
            hidesDonate: hidesDonate
        )
        if hasEnd {
            viewModel.endViewModel = WMFYearInReviewEndViewModel(isContributor: false)
        }
        return viewModel
    }

    // MARK: - Page count

    @Test
    func theEndScreenAddsOnePage() {
        let viewModel = makeViewModel()
        #expect(viewModel.pageCount == 4)
    }

    @Test
    func withoutAnEndScreenThePagesAreTheSlides() {
        let viewModel = makeViewModel(hasEnd: false)
        #expect(viewModel.pageCount == 3)
    }

    // MARK: - Position

    @Test
    func aSlideIsNotTheEndScreen() {
        let viewModel = makeViewModel()
        #expect(viewModel.isOnEnd == false)
        #expect(viewModel.currentPageIndex == 0)
    }

    @Test
    func theEndScreenIsThePageAfterTheLastSlide() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.isOnEnd)
        #expect(viewModel.currentPageIndex == 3)
        #expect(viewModel.currentSlideIndex == 2)
    }

    // MARK: - End screen state

    @Test
    func theEndScreenHasNoCurrentSlide() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.currentSlide == nil)
        #expect(viewModel.showsShareButton == false)
    }

    @Test
    func theEndScreenHasNoToolbarButtons() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsShareButton == false)
        #expect(viewModel.showsDonateButton == false)
    }

    @Test
    func theEndScreenUsesDarkControls() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.currentContentColor == WMFYearInReviewSlideViewModel.ContentStyle.dark.color)
    }

    @Test
    func theEndScreenUsesLightControlsAfterTheSkyScrolledAway() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        viewModel.endUsesLightContent = true

        #expect(viewModel.currentContentColor == WMFYearInReviewSlideViewModel.ContentStyle.light.color)
    }

    // MARK: - Share highlights

    /// The view model keeps the coordinator as a weak reference, so the caller keeps the spy.
    private func makeViewModel(coordinator: WMFYearInReviewCoordinating) -> WMFYearInReviewViewModel {
        let viewModel = WMFYearInReviewViewModel(
            slides: [WMFYearInReviewSlideViewModel(id: "slide0", loggingID: "logging0")],
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging,
            hidesDonate: { false }
        )
        viewModel.endViewModel = WMFYearInReviewEndViewModel(isContributor: false)
        return viewModel
    }

    private static func highlights(articlesRead: Int? = 120, minutesRead: Int? = 900) -> WMFYearInReviewHighlights {
        WMFYearInReviewHighlights(
            articlesRead: articlesRead,
            minutesRead: minutesRead,
            rotation: [],
            rabbitHole: nil,
            nicheCategory: nil,
            localizedStrings: .init(title: "", articlesReadLabel: "", minutesReadLabel: "", rotationLabel: "", rotationRank: { "\($0)" }, rabbitHoleLabel: "", nicheCategoryLabel: "", createdWith: "")
        )
    }

    @Test
    func theEndScreenSharesTheHighlights() {
        let coordinator = EndCoordinatorSpy()
        let viewModel = makeViewModel(coordinator: coordinator)
        viewModel.highlights = Self.highlights()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsShareHighlightsButton)
        #expect(viewModel.showsShareButton == false, "the end screen has no toolbar share button")

        let buttonFrame = CGRect(x: 100, y: 400, width: 180, height: 44)
        viewModel.tappedShareHighlights(sourceRect: { buttonFrame })

        #expect(logging.sharedHighlights == 1)
        #expect(logging.shared.isEmpty, "a highlights share is not logged as a slide share")
        if case .shareHighlights(let getSourceRect) = coordinator.actions.last {
            #expect(getSourceRect() == buttonFrame, "the share sheet on iPad points at the button")
        } else {
            Issue.record("expected the highlights to be shared, got \(String(describing: coordinator.actions.last))")
        }
    }

    @Test
    func withoutHighlightsTheEndScreenHasNoShareButton() {
        let coordinator = EndCoordinatorSpy()
        let viewModel = makeViewModel(coordinator: coordinator)

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        viewModel.tappedShareHighlights(sourceRect: { .zero })

        #expect(viewModel.showsShareHighlightsButton == false, "the collective flow has no highlights")
        #expect(coordinator.actions.isEmpty)
        #expect(logging.sharedHighlights == 0)
    }

    @Test
    func withOneHighlightTheEndScreenHasNoShareButton() {
        let viewModel = makeViewModel()
        viewModel.highlights = Self.highlights(minutesRead: nil)

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsShareHighlightsButton == false)
    }

    @Test
    func goingToTheEndScreenLogsNoSlideAppearance() {
        let viewModel = makeViewModel()
        logging.appeared.removeAll()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(logging.appeared.isEmpty)
    }
}

@MainActor
@Suite
struct WMFYearInReviewEndViewModelTests {

    @Test
    func aContributorGetsTheGiftCardFirst() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: true)
        #expect(viewModel.cards.map(\.id) == ["contributorGift", "whichWikipedia"])
    }

    @Test
    func aNonContributorGetsOnlyTheQuizCard() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: false)
        #expect(viewModel.cards.map(\.id) == ["whichWikipedia"])
    }

    @Test
    func anEnglishReaderGetsTheTopReadCardBeforeTheQuizCard() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: false, hasEnglishAppLanguage: true)
        #expect(viewModel.cards.map(\.id) == ["topRead", "whichWikipedia"])
    }

    @Test
    func anEnglishContributorGetsTheGiftCardThenTheTopReadCard() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: true, hasEnglishAppLanguage: true)
        #expect(viewModel.cards.map(\.id) == ["contributorGift", "topRead", "whichWikipedia"])
    }

    @Test
    func aReaderWithoutEnglishDoesNotGetTheTopReadCard() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: true, hasEnglishAppLanguage: false)
        #expect(!viewModel.cards.contains { $0.action == .topRead })
    }

    @Test
    func theTopReadCardCapitalizesItsTitleInEnglish() throws {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: false, hasEnglishAppLanguage: true)
        let card = try #require(viewModel.cards.first { $0.action == .topRead })
        #expect(card.uppercasedTitle == "2026'S MOST-READ ARTICLES")
    }

    @Test
    func aTitleWithAnEnglishLocaleKeepsTheDotlessCapitalI() {
        // Turkish capitalizes "i" as "İ". The English locale keeps it "I", whatever the device locale.
        let english = WMFYearInReviewEndViewModel.Card(id: "en", title: "articles", body: "", buttonTitle: "", action: .topRead, uppercaseLocale: Locale(identifier: "en"))
        #expect(english.uppercasedTitle == "ARTICLES")
        #expect("articles".uppercased(with: Locale(identifier: "tr")) == "ARTİCLES")
    }

    @Test
    func aTranslatedTitleIsCapitalizedWithTheDeviceLocale() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: true, hasEnglishAppLanguage: true)
        for card in viewModel.cards where card.action != .topRead {
            #expect(card.uppercaseLocale == nil)
            #expect(card.uppercasedTitle == card.title.localizedUppercase)
        }
    }

    @Test
    func theTopReadCardCallsItsAction() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: false, hasEnglishAppLanguage: true)
        var tappedTopRead = 0
        var tappedQuiz = 0
        viewModel.didTapTopRead = { tappedTopRead += 1 }
        viewModel.didTapWhichWikipedia = { tappedQuiz += 1 }

        viewModel.didTap(viewModel.cards[0])
        #expect(tappedTopRead == 1)
        #expect(tappedQuiz == 0)
    }

    @Test
    func eachCardCallsItsOwnAction() {
        let viewModel = WMFYearInReviewEndViewModel(isContributor: true)
        var tappedStore = 0
        var tappedQuiz = 0
        viewModel.didTapStore = { tappedStore += 1 }
        viewModel.didTapWhichWikipedia = { tappedQuiz += 1 }

        viewModel.didTap(viewModel.cards[0])
        #expect(tappedStore == 1)
        #expect(tappedQuiz == 0)

        viewModel.didTap(viewModel.cards[1])
        #expect(tappedStore == 1)
        #expect(tappedQuiz == 1)
    }
}
