import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class CoordinatorSpy: WMFYearInReviewCoordinating {
    var actions: [WMFYearInReviewAction] = []

    func handleYearInReviewAction(_ action: WMFYearInReviewAction) {
        actions.append(action)
    }
}

@MainActor
private final class LoggingSpy: WMFYearInReviewLoggingDelegate {
    var appeared: [String] = []
    var done: [String] = []
    var next: [String] = []
    var donate: [String] = []
    var share: [String] = []

    func logYearInReviewIntroDidTapLearnMore() {}
    func logYearInReviewSlideDidAppear(slideLoggingID: String) { appeared.append(slideLoggingID) }
    func logYearInReviewDidTapDone(slideLoggingID: String) { done.append(slideLoggingID) }
    func logYearInReviewDidTapNext(slideLoggingID: String) { next.append(slideLoggingID) }
    func logYearInReviewDidTapDonate(slideLoggingID: String) { donate.append(slideLoggingID) }
    func logYearInReviewDidTapShare(slideLoggingID: String) { share.append(slideLoggingID) }
}

@MainActor
@Suite
struct WMFYearInReviewViewModelTests {

    // The view model holds both delegates weakly, so a test has to retain its spies.
    private let coordinator = CoordinatorSpy()
    private let logging = LoggingSpy()

    private static func strings() -> WMFYearInReviewViewModel.LocalizedStrings {
        return WMFYearInReviewViewModel.LocalizedStrings(
            wIconAccessibilityLabel: "Wikipedia",
            closeButtonAccessibilityLabel: "Close",
            moreButtonAccessibilityLabel: "More",
            shareButtonTitle: "Share",
            donateButtonTitle: "Donate",
            learnMoreButtonTitle: "Learn more",
            shareFeedbackButtonTitle: "Share feedback",
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    private static func slides(_ count: Int) -> [WMFYearInReviewSlideViewModel] {
        return (0..<count).map { index in
            WMFYearInReviewSlideViewModel(
                id: "slide\(index)",
                loggingID: "logging\(index)",
                backgroundColor: .white
            )
        }
    }

    private func makeViewModel(slideCount: Int = 3) -> WMFYearInReviewViewModel {
        return WMFYearInReviewViewModel(
            slides: Self.slides(slideCount),
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging
        )
    }

    // MARK: - Position

    @Test
    func theFirstSlideIsSelectedOnInit() {
        let viewModel = makeViewModel()
        #expect(viewModel.currentSlideID == "slide0")
        #expect(viewModel.currentSlideIndex == 0)
        #expect(viewModel.currentSlide?.id == "slide0")
    }

    /// `.scrollPosition(id:)` reports nil until the user scrolls, so a nil id has to resolve
    /// to the first slide. Without the fallback the first slide renders with no content.
    @Test
    func aNilPositionFallsBackToTheFirstSlide() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = nil
        #expect(viewModel.currentSlideIndex == 0)
        #expect(viewModel.currentSlide?.id == "slide0")
    }

    @Test
    func anUnknownPositionFallsBackToTheFirstSlide() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = "not-a-slide"
        #expect(viewModel.currentSlideIndex == 0)
        #expect(viewModel.currentSlide?.id == "slide0")
    }

    @Test
    func thereIsNoCurrentSlideWithoutSlides() {
        let viewModel = makeViewModel(slideCount: 0)
        #expect(viewModel.currentSlide == nil)
        #expect(viewModel.currentSlideID == nil)
    }

    @Test
    func isLastSlideTracksThePosition() {
        let viewModel = makeViewModel()
        #expect(viewModel.isLastSlide == false)

        viewModel.currentSlideID = "slide2"
        #expect(viewModel.isLastSlide)
    }

    /// One slide is simultaneously the first and the last, so `tappedNext` must not run off
    /// the end of the array.
    @Test
    func aSingleSlideIsTheLastSlide() {
        let viewModel = makeViewModel(slideCount: 1)
        #expect(viewModel.isLastSlide)

        viewModel.tappedNext()
        #expect(viewModel.currentSlideID == "slide0")
    }

    @Test
    func anEmptySlideSetIsTreatedAsTheLastSlide() {
        let viewModel = makeViewModel(slideCount: 0)
        #expect(viewModel.isLastSlide)

        viewModel.tappedNext()
        #expect(viewModel.currentSlideID == nil)
    }

    // MARK: - Advancing

    @Test
    func tappedNextAdvancesByIdAndLogs() {
        let viewModel = makeViewModel()

        viewModel.tappedNext()

        #expect(viewModel.currentSlideID == "slide1")
        #expect(logging.next == ["logging0"])
    }

    @Test
    func tappedNextStopsOnTheLastSlide() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = "slide2"
        logging.next.removeAll()

        viewModel.tappedNext()

        #expect(viewModel.currentSlideID == "slide2")
        #expect(logging.next.isEmpty)
    }

    // MARK: - Slide appearance logging

    @Test
    func onAppearLogsTheCurrentSlide() {
        let viewModel = makeViewModel()

        viewModel.onAppear()

        #expect(logging.appeared == ["logging0"])
    }

    @Test
    func changingThePositionLogsTheNewSlide() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = "slide1"

        #expect(logging.appeared == ["logging1"])
    }

    /// Scroll bindings can reassign the same value repeatedly; an impression should not be
    /// logged twice for one slide.
    @Test
    func reassigningTheSamePositionDoesNotLogAgain() {
        let viewModel = makeViewModel()

        viewModel.currentSlideID = "slide1"
        viewModel.currentSlideID = "slide1"

        #expect(logging.appeared == ["logging1"])
    }

    // MARK: - Actions

    @Test
    func tappedCloseLogsAndAsksTheCoordinatorToClose() {
        let viewModel = makeViewModel()

        viewModel.tappedClose()

        #expect(logging.done == ["logging0"])
        #expect(coordinator.actions.count == 1)
        if case .close = coordinator.actions[0] {} else {
            Issue.record("expected a close action")
        }
    }

    @Test
    func tappedLearnMoreCarriesTheSlideLoggingID() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = "slide1"

        viewModel.tappedLearnMore()

        if case .learnMore(let slideLoggingID) = coordinator.actions.last {
            #expect(slideLoggingID == "logging1")
        } else {
            Issue.record("expected a learnMore action")
        }
    }

    @Test
    func tappedShareFeedbackCarriesTheSlideLoggingID() {
        let viewModel = makeViewModel()

        viewModel.tappedShareFeedback()

        if case .shareFeedback(let slideLoggingID) = coordinator.actions.last {
            #expect(slideLoggingID == "logging0")
        } else {
            Issue.record("expected a shareFeedback action")
        }
    }

    @Test
    func tappedShareLogsAndCarriesTheSlideID() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = "slide2"

        viewModel.tappedShare()

        #expect(logging.share == ["logging2"])
        if case .share(let slideID) = coordinator.actions.last {
            #expect(slideID == "slide2")
        } else {
            Issue.record("expected a share action")
        }
    }

    @Test
    func tappedDonateLogsAndPassesTheSourceRect() {
        let viewModel = makeViewModel()
        let expectedRect = CGRect(x: 1, y: 2, width: 3, height: 4)

        viewModel.tappedDonate(sourceRect: { expectedRect })

        #expect(logging.donate == ["logging0"])
        if case .donate(let getSourceRect, let slideLoggingID) = coordinator.actions.last {
            #expect(slideLoggingID == "logging0")
            #expect(getSourceRect() == expectedRect)
        } else {
            Issue.record("expected a donate action")
        }
    }

    @Test
    func shareAndDonateDoNothingWithoutASlide() {
        let viewModel = makeViewModel(slideCount: 0)

        viewModel.tappedShare()
        viewModel.tappedDonate(sourceRect: { .zero })

        #expect(coordinator.actions.isEmpty)
        #expect(logging.share.isEmpty)
        #expect(logging.donate.isEmpty)
    }

    // MARK: - Accessibility

    @Test
    func theSlidePositionReadsAsOneBased() {
        let viewModel = makeViewModel()
        #expect(viewModel.slidePositionAccessibilityValue == "1 of 3")

        viewModel.currentSlideID = "slide2"
        #expect(viewModel.slidePositionAccessibilityValue == "3 of 3")
    }

    // MARK: - Donate button

    /// Only the slide-level half of the rule is covered here. The region half calls
    /// WMFYearInReviewDataController directly, so it cannot be exercised without a seam.
    @Test
    func aSlideThatHidesDonateIsRespected() {
        let viewModel = WMFYearInReviewViewModel(
            slides: [
                WMFYearInReviewSlideViewModel(
                    id: "intro",
                    loggingID: "intro",
                    backgroundColor: .white,
                    showsDonateButton: false
                )
            ],
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging
        )

        #expect(viewModel.showsDonateButton == false)
    }
}
