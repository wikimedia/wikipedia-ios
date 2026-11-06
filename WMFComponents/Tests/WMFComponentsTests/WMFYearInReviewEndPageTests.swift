import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class EndLoggingSpy: WMFYearInReviewLoggingDelegate {
    var appeared: [String] = []
    var donate: [String] = []

    func logYearInReviewIntroDidTapLearnMore() {}
    func logYearInReviewSlideDidAppear(slideLoggingID: String) { appeared.append(slideLoggingID) }
    func logYearInReviewDidTapDone(slideLoggingID: String) {}
    func logYearInReviewDidTapNext(slideLoggingID: String) {}
    func logYearInReviewDidTapDonate(slideLoggingID: String) { donate.append(slideLoggingID) }
    func logYearInReviewDidTapShare(slideLoggingID: String) {}
}

@MainActor
@Suite
struct WMFYearInReviewEndPageTests {

    // The view model keeps the logging delegate as a weak reference, so the test keeps the spy.
    private let logging = EndLoggingSpy()

    private static func strings() -> WMFYearInReviewViewModel.LocalizedStrings {
        return WMFYearInReviewViewModel.LocalizedStrings(
            wIconAccessibilityLabel: "Wikipedia",
            closeButtonAccessibilityLabel: "Close",
            moreButtonAccessibilityLabel: "More",
            shareButtonTitle: "Share",
            donateButtonTitle: "Donate",
            learnMoreButtonTitle: "Learn more",
            aboutInsightsButtonTitle: "About your insights",
            shareFeedbackButtonTitle: "Share feedback",
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
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
        #expect(viewModel.slidePositionAccessibilityValue == "4 of 4")
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
