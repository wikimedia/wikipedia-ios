import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class EndLoggingSpy: WMFYearInReviewLoggingDelegate {
    var appeared: [String] = []

    func logYearInReviewIntroDidTapLearnMore() {}
    func logYearInReviewSlideDidAppear(slideLoggingID: String) { appeared.append(slideLoggingID) }
    func logYearInReviewDidTapDone(slideLoggingID: String) {}
    func logYearInReviewDidTapNext(slideLoggingID: String) {}
    func logYearInReviewDidTapDonate(slideLoggingID: String) {}
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

    private func makeViewModel(slideCount: Int = 3, hasEnd: Bool = true) -> WMFYearInReviewViewModel {
        let slides = (0..<slideCount).map { index in
            WMFYearInReviewSlideViewModel(id: "slide\(index)", loggingID: "logging\(index)")
        }
        let viewModel = WMFYearInReviewViewModel(
            slides: slides,
            localizedStrings: Self.strings(),
            coordinatorDelegate: nil,
            loggingDelegate: logging
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
