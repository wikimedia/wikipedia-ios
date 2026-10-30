import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class EndLoggingSpy: WMFYearInReviewLoggingDelegate {
    var appeared: [String] = []
    var shared: [String] = []

    func logYearInReviewIntroDidTapLearnMore() {}
    func logYearInReviewSlideDidAppear(slideLoggingID: String) { appeared.append(slideLoggingID) }
    func logYearInReviewDidTapDone(slideLoggingID: String) {}
    func logYearInReviewDidTapNext(slideLoggingID: String) {}
    func logYearInReviewDidTapDonate(slideLoggingID: String) {}
    func logYearInReviewDidTapShare(slideLoggingID: String) { shared.append(slideLoggingID) }
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
            wIconAccessibilityLabel: "Wikipedia",
            closeButtonAccessibilityLabel: "Close",
            moreButtonAccessibilityLabel: "More",
            shareButtonTitle: "Share",
            shareHighlightsButtonTitle: "Share highlights",
            donateButtonTitle: "Donate",
            learnMoreButtonTitle: "Learn more",
            aboutInsightsButtonTitle: "About your insights",
            shareFeedbackButtonTitle: "Share feedback",
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    private func makeViewModel(slideCount: Int = 3, hasEnd: Bool = true, hidesDonate: @escaping () -> Bool = { false }, coordinator: WMFYearInReviewCoordinating? = nil) -> WMFYearInReviewViewModel {
        let slides = (0..<slideCount).map { index in
            WMFYearInReviewSlideViewModel(id: "slide\(index)", loggingID: "logging\(index)")
        }
        let viewModel = WMFYearInReviewViewModel(
            slides: slides,
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
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
        #expect(viewModel.showsDonateButton == false)
    }

    @Test
    func theEndScreenToolbarIsTheBlackChromeColor() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.currentChromeColor == WMFYearInReviewViewModel.chromeBackgroundColor)
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

    private static func highlights(articlesRead: Int? = 120, minutesRead: Int? = 900) -> WMFYearInReviewHighlights {
        WMFYearInReviewHighlights(
            articlesRead: articlesRead,
            minutesRead: minutesRead,
            rotation: [],
            rabbitHole: nil,
            nicheCategory: nil,
            localizedStrings: .init(title: "", articlesReadLabel: "", minutesReadLabel: "", rotationLabel: "", rabbitHoleLabel: "", nicheCategoryLabel: "", createdWith: "")
        )
    }

    @Test
    func theEndScreenSharesTheHighlights() {
        let coordinator = EndCoordinatorSpy()
        let viewModel = makeViewModel(coordinator: coordinator)
        viewModel.highlights = Self.highlights()

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsShareButton)
        #expect(viewModel.shareButtonTitle == "Share highlights")

        viewModel.tappedShare()

        #expect(logging.shared == [WMFYearInReviewViewModel.endLoggingID])
        if case .shareHighlights = coordinator.actions.last {} else {
            Issue.record("expected the highlights to be shared, got \(String(describing: coordinator.actions.last))")
        }
    }

    @Test
    func aSlideKeepsItsOwnShareTitle() {
        let viewModel = makeViewModel()
        viewModel.highlights = Self.highlights()

        #expect(viewModel.shareButtonTitle == "Share")
    }

    @Test
    func withoutHighlightsTheEndScreenHasNoShareButton() {
        let coordinator = EndCoordinatorSpy()
        let viewModel = makeViewModel(coordinator: coordinator)

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID
        viewModel.tappedShare()

        #expect(viewModel.showsShareButton == false, "the collective flow has no highlights")
        #expect(coordinator.actions.isEmpty)
        #expect(logging.shared.isEmpty)
    }

    @Test
    func withOneHighlightTheEndScreenHasNoShareButton() {
        let viewModel = makeViewModel()
        viewModel.highlights = Self.highlights(minutesRead: nil)

        viewModel.currentSlideID = WMFYearInReviewViewModel.endPageID

        #expect(viewModel.showsShareButton == false)
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
