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
            aboutInsightsButtonTitle: "About your insights",
            shareFeedbackButtonTitle: "Share feedback",
            slidePositionAccessibilityValue: { current, total in "\(current) of \(total)" }
        )
    }

    private static func slides(_ count: Int) -> [WMFYearInReviewSlideViewModel] {
        return (0..<count).map { index in
            WMFYearInReviewSlideViewModel(
                id: "slide\(index)",
                loggingID: "logging\(index)",
            )
        }
    }

    private func makeViewModel(slideCount: Int = 3) -> WMFYearInReviewViewModel {
        return WMFYearInReviewViewModel(
            slides: Self.slides(slideCount),
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging,
            hidesDonate: { false }
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
    func tappedAboutInsightsCarriesTheSlideLoggingID() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = "slide2"

        viewModel.tappedAboutInsights()

        if case .aboutInsights(let slideLoggingID) = coordinator.actions.last {
            #expect(slideLoggingID == "logging2")
        } else {
            Issue.record("expected an aboutInsights action")
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

    /// The slide-level half of the rule. `theCountryCheckHidesTheToolbarDonateButton` covers the region half.
    @Test
    func aSlideThatHidesDonateIsRespected() {
        let viewModel = WMFYearInReviewViewModel(
            slides: [
                WMFYearInReviewSlideViewModel(
                    id: "intro",
                    loggingID: "intro",
                    showsDonateButton: false
                )
            ],
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging,
            hidesDonate: { false }
        )

        #expect(viewModel.showsDonateButton == false)
    }

    // MARK: - Replacing a slide

    /// After a donation the "You matter" slide becomes "Thank you", and the reader stays on it.
    @Test
    func replacingTheCurrentSlideKeepsTheReaderOnIt() {
        let viewModel = makeViewModel()
        viewModel.currentSlideID = "slide2"

        viewModel.replaceSlide(id: "slide2", with: WMFYearInReviewSlideViewModel(id: "contributor", loggingID: "contributor"))

        #expect(viewModel.slides.map(\.id) == ["slide0", "slide1", "contributor"])
        #expect(viewModel.currentSlideID == "contributor")
        #expect(viewModel.showsDonateButton)
    }

    @Test
    func replacingAnotherSlideDoesNotMoveTheReader() {
        let viewModel = makeViewModel()

        viewModel.replaceSlide(id: "slide2", with: WMFYearInReviewSlideViewModel(id: "contributor", loggingID: "contributor"))

        #expect(viewModel.slides.map(\.id) == ["slide0", "slide1", "contributor"])
        #expect(viewModel.currentSlideID == "slide0")
    }

    @Test
    func replacingAMissingSlideChangesNothing() {
        let viewModel = makeViewModel()

        viewModel.replaceSlide(id: "nonContributor", with: WMFYearInReviewSlideViewModel(id: "contributor", loggingID: "contributor"))

        #expect(viewModel.slides.map(\.id) == ["slide0", "slide1", "slide2"])
    }

    /// A slide with its own donate button does not show the toolbar buttons.
    @Test
    func aSlideWithAPrimaryDonateButtonHidesTheToolbarButtons() {
        let viewModel = WMFYearInReviewViewModel(
            slides: [
                WMFYearInReviewSlideViewModel(
                    id: "nonContributor",
                    loggingID: "nonContributor",
                    showsPrimaryDonateButton: true
                )
            ],
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging,
            hidesDonate: { false }
        )

        #expect(viewModel.showsDonateButton == false)
        #expect(viewModel.showsShareButton == false)
    }

    @Test
    func aSlideWithoutAPrimaryDonateButtonShowsTheShareButton() {
        let viewModel = makeViewModel()

        #expect(viewModel.showsShareButton)
    }

    /// Where donations are not accepted, or when the country check cannot run, the toolbar does
    /// not show the donate button.
    @Test
    func theCountryCheckHidesTheToolbarDonateButton() {
        let viewModel = WMFYearInReviewViewModel(
            slides: Self.slides(1),
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging,
            hidesDonate: { true }
        )

        #expect(viewModel.showsDonateButton == false)
        #expect(viewModel.showsShareButton)
    }

    // MARK: - Content color

    /// The slides in this suite use the default `.light` style.
    @Test
    func theSlideStyleSetsTheColorBeforeTheSlideLoads() {
        let viewModel = makeViewModel()
        #expect(viewModel.currentContentColor == WMFColor.white)
    }

    /// The flag that the .riv sets wins over the style of the slide view model.
    @Test
    func theLoadedFlagSetsTheColor() {
        let viewModel = makeViewModel()

        viewModel.slideDidLoad(lightContent: false, slideID: "slide0")
        #expect(viewModel.currentContentColor == WMFColor.gray700)

        viewModel.slideDidLoad(lightContent: true, slideID: "slide0")
        #expect(viewModel.currentContentColor == WMFColor.white)
    }

    /// A slide that loads off screen must not change the color of the current slide.
    @Test
    func anotherSlideFlagDoesNotChangeTheCurrentColor() {
        let viewModel = makeViewModel()

        viewModel.slideDidLoad(lightContent: false, slideID: "slide1")

        #expect(viewModel.currentContentColor == WMFColor.white)
        viewModel.currentSlideID = "slide1"
        #expect(viewModel.currentContentColor == WMFColor.gray700)
    }

    // MARK: - Answers

    private func makeViewModelWithAnswer() -> WMFYearInReviewViewModel {
        let guess = WMFYearInReviewSlideViewModel(
            id: "guess",
            loggingID: "guess",
            answer: WMFYearInReviewSlideViewModel(id: "reveal", loggingID: "reveal")
        )
        return WMFYearInReviewViewModel(
            slides: [guess, WMFYearInReviewSlideViewModel(id: "last", loggingID: "last")],
            localizedStrings: Self.strings(),
            coordinatorDelegate: coordinator,
            loggingDelegate: logging,
            hidesDonate: { false }
        )
    }

    @Test
    func aSlideAndItsAnswerTakeOnePagerPosition() {
        let viewModel = makeViewModelWithAnswer()

        #expect(viewModel.pagerSlides.map(\.id) == ["guess", "last"])
    }

    /// A VoiceOver reader cannot tap an answer in the .riv, so the answer is the next slide.
    @Test
    func withVoiceOverTheAnswerIsTheNextSlide() {
        let viewModel = makeViewModelWithAnswer()
        viewModel.showsAnswersAsSlides = true

        #expect(viewModel.pagerSlides.map(\.id) == ["guess", "reveal", "last"])
        viewModel.currentSlideID = "reveal"
        #expect(viewModel.currentSlideIndex == 1)
        #expect(viewModel.slidePositionAccessibilityValue == "2 of 3")
    }

    /// When VoiceOver turns off on the answer, the position is the slide that has the answer.
    @Test
    func anAnswerThatIsNotASlideKeepsThePositionOfItsSlide() {
        let viewModel = makeViewModelWithAnswer()
        viewModel.showsAnswersAsSlides = true
        viewModel.currentSlideID = "reveal"

        viewModel.showsAnswersAsSlides = false

        #expect(viewModel.currentSlideIndex == 0)
        #expect(viewModel.currentSlide?.id == "guess")
    }
}
