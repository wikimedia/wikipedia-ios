import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class EndLoggingSpy: WMFYearInReviewLoggingDelegate {
    var appeared: [String] = []
    var donate: [String] = []
    var done: [String] = []
    var shared: [String] = []
    var sharedHighlights = 0

    func logYearInReviewIntroDidTapLearnMore() {}
    func logYearInReviewSlideDidAppear(slideLoggingID: String) { appeared.append(slideLoggingID) }
    func logYearInReviewDidTapDone(slideLoggingID: String) { done.append(slideLoggingID) }
    func logYearInReviewDidTapNext(slideLoggingID: String) {}
    func logYearInReviewDidTapDonate(slideLoggingID: String) { donate.append(slideLoggingID) }
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

    /// - Parameter slidesShowDonate: `false` is like "You matter", which has its own donate button
    ///   instead of the toolbar button.
    private func makeViewModel(slideCount: Int = 3, hasEnd: Bool = true, slidesShowDonate: Bool = true, hidesDonate: @escaping () -> Bool = { false }) -> WMFYearInReviewViewModel {
        let slides = (0..<slideCount).map { index in
            WMFYearInReviewSlideViewModel(id: "slide\(index)", loggingID: "logging\(index)", showsDonateButton: slidesShowDonate)
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

    /// The end screen keeps the donate button of the slide chrome, but not the share button (T438574).
    @Test
    func theEndScreenShowsTheDonateButtonButNotTheShareButton() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsShareButton == false)
        #expect(viewModel.showsDonateButton)
        #expect(viewModel.toolbarShowsDonateButton)
    }

    @Test
    func theEndScreenHidesTheDonateButtonWhereDonationsAreNotAccepted() {
        let viewModel = makeViewModel(hidesDonate: { true })

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsDonateButton == false)
        #expect(viewModel.toolbarShowsDonateButton == false)
    }

    /// The donate button of the last slide stays in the toolbar during the swipe to the end screen.
    @Test
    func theDonateButtonOfTheLastSlideDoesNotFade() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = "slide2"

        #expect(viewModel.toolbarShowsDonateButton)
        #expect(viewModel.toolbarDonateButtonFadesIn == false)
    }

    /// After a last slide without a toolbar donate button, the end screen's button fades in during the swipe.
    @Test
    func theEndScreenDonateButtonFadesInAfterALastSlideWithoutOne() {
        let viewModel = makeViewModel(slidesShowDonate: false)

        viewModel.currentSlideID = "slide2"
        #expect(viewModel.showsDonateButton == false)
        #expect(viewModel.toolbarShowsDonateButton)
        #expect(viewModel.toolbarDonateButtonFadesIn)

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        #expect(viewModel.showsDonateButton)
        #expect(viewModel.toolbarShowsDonateButton)
        #expect(viewModel.toolbarDonateButtonFadesIn)
    }

    /// Only the last slide holds the end screen's donate button.
    @Test
    func anEarlierSlideWithoutADonateButtonHasNone() {
        let viewModel = makeViewModel(slidesShowDonate: false)

        viewModel.currentSlideID = "slide1"

        #expect(viewModel.toolbarShowsDonateButton == false)
    }

    @Test
    func withoutAnEndScreenTheLastSlideKeepsItsOwnButtons() {
        let viewModel = makeViewModel(hasEnd: false, slidesShowDonate: false)

        viewModel.currentSlideID = "slide2"

        #expect(viewModel.toolbarShowsDonateButton == false)
    }

    /// The same page name as Android, so the campaign ID is `appmenu_yir_end`.
    @Test
    func tappingDonateOnTheEndScreenLogsTheEndPage() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        viewModel.tappedDonate(sourceRect: { .zero })

        #expect(logging.donate == [WMFYearInReviewViewModel.endLoggingID])
        #expect(WMFYearInReviewViewModel.endLoggingID == "end")
    }

    /// Only the donate tap uses the end page name. Done keeps the empty ID it had before.
    @Test
    func tappingDoneOnTheEndScreenKeepsTheEmptyLoggingID() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        viewModel.tappedClose()

        #expect(logging.done == [""])
    }

    /// The end screen can become current without a scroll step that sets the reveal to 1, for
    /// example after a VoiceOver page scroll. At rest, the toolbar follows the current page.
    @Test
    func theToolbarRevealFollowsTheCurrentPageAtRest() {
        let viewModel = makeViewModel(slidesShowDonate: false)

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        #expect(viewModel.endPageReveal.value == 0)
        #expect(viewModel.toolbarEndReveal == 1)

        viewModel.pagerDidScroll(toPosition: 2.4)
        #expect(viewModel.toolbarEndReveal == viewModel.endPageReveal.value)

        viewModel.pagerDidScroll(toPosition: 2)
        viewModel.currentSlideID = "slide2"
        #expect(viewModel.toolbarEndReveal == 0)
    }

    /// The current page changes only when the pager is within 1 pt of a page. Until then, the
    /// toolbar follows the swipe, so the donate button does not jump to the page the reader left.
    @Test
    func theToolbarRevealFollowsTheSwipeUntilThePageChanges() {
        let viewModel = makeViewModel(slidesShowDonate: false)

        // Swiping back from the end screen, a few points before the last slide.
        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        viewModel.pagerDidScroll(toPosition: 2.005)
        #expect(viewModel.toolbarEndReveal == viewModel.endPageReveal.value)
        #expect(viewModel.toolbarEndReveal < 0.5)

        // Swiping to the end screen, a few points before it.
        viewModel.pagerDidScroll(toPosition: 2)
        viewModel.currentSlideID = "slide2"
        viewModel.pagerDidScroll(toPosition: 2.995)
        #expect(viewModel.toolbarEndReveal == viewModel.endPageReveal.value)
        #expect(viewModel.toolbarEndReveal > 0.5)
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
