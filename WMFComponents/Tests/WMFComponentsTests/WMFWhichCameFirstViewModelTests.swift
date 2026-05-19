import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFWhichCameFirstViewModelTests: XCTestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [enLanguage])
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
    }

    // MARK: - Fixtures

    var enLanguage: WMFLanguage {
        WMFLanguage(languageCode: "en", languageVariantCode: nil)
    }

    var enProject: WMFProject {
        .wikipedia(enLanguage)
    }

    func makeViewModel() -> WMFWhichCameFirstViewModel {
        WMFWhichCameFirstViewModel(
            date: "2026-01-06",
            project: enProject
        )
    }

    // MARK: - Initial State

    func testInitialPhaseIsLoading() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.phase, .loading)
    }

    func testInitialScoreIsZero() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.score, 0)
    }

    func testInitialCurrentIndexIsZero() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.currentIndex, 0)
    }

    func testInitialProgressResultsIsEmpty() {
        let viewModel = makeViewModel()
        XCTAssertTrue(viewModel.progressResults.isEmpty)
    }

    func testInitialCardViewModelsAreNil() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.cardViewModelA)
        XCTAssertNil(viewModel.cardViewModelB)
    }

    func testInitialRevealStateIsNil() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.revealState)
    }

    func testInitialSelectedOptionIsNil() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.selectedOption)
    }

    func testInitialShowFlagsAreFalse() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.showTitle)
        XCTAssertFalse(viewModel.showCardA)
        XCTAssertFalse(viewModel.showCardB)
    }

    // MARK: - select(_:)

    func testSelectInPresentingPhaseUpdatesSelectedOption() {
        let viewModel = makeViewModel()
        viewModel.phase = .presenting
        viewModel.select("A")
        XCTAssertEqual(viewModel.selectedOption, "A")
    }

    func testSelectInPresentingPhaseTransitionsToAwaitingSubmission() {
        let viewModel = makeViewModel()
        viewModel.phase = .presenting
        viewModel.select("A")
        XCTAssertEqual(viewModel.phase, .awaitingSubmission)
    }

    func testSelectInAwaitingSubmissionPhaseUpdatesSelectedOption() {
        let viewModel = makeViewModel()
        viewModel.phase = .awaitingSubmission
        viewModel.select("B")
        XCTAssertEqual(viewModel.selectedOption, "B")
    }

    func testSelectDoesNothingWhenRevealing() {
        let viewModel = makeViewModel()
        viewModel.phase = .revealing
        viewModel.select("A")
        XCTAssertNil(viewModel.selectedOption)
        XCTAssertEqual(viewModel.phase, .revealing)
    }

    func testSelectDoesNothingWhenComplete() {
        let viewModel = makeViewModel()
        viewModel.phase = .complete
        viewModel.select("A")
        XCTAssertNil(viewModel.selectedOption)
        XCTAssertEqual(viewModel.phase, .complete)
    }

    func testSelectASetsCardASelectedCardBUnselected() {
        let viewModel = makeViewModel()
        viewModel.cardViewModelA = WMFOnThisDayCardViewModel(event: .mockEvent())
        viewModel.cardViewModelB = WMFOnThisDayCardViewModel(event: .mockEvent())
        viewModel.phase = .presenting
        viewModel.select("A")
        XCTAssertTrue(viewModel.cardViewModelA?.isSelected == true)
        XCTAssertFalse(viewModel.cardViewModelB?.isSelected == true)
    }

    func testSelectBSetsCardBSelectedCardAUnselected() {
        let viewModel = makeViewModel()
        viewModel.cardViewModelA = WMFOnThisDayCardViewModel(event: .mockEvent())
        viewModel.cardViewModelB = WMFOnThisDayCardViewModel(event: .mockEvent())
        viewModel.phase = .presenting
        viewModel.select("B")
        XCTAssertFalse(viewModel.cardViewModelA?.isSelected == true)
        XCTAssertTrue(viewModel.cardViewModelB?.isSelected == true)
    }

    func testSelectCanSwitchFromAToB() {
        let viewModel = makeViewModel()
        viewModel.cardViewModelA = WMFOnThisDayCardViewModel(event: .mockEvent())
        viewModel.cardViewModelB = WMFOnThisDayCardViewModel(event: .mockEvent())
        viewModel.phase = .presenting
        viewModel.select("A")
        viewModel.select("B")
        XCTAssertEqual(viewModel.selectedOption, "B")
        XCTAssertFalse(viewModel.cardViewModelA?.isSelected == true)
        XCTAssertTrue(viewModel.cardViewModelB?.isSelected == true)
    }

    // MARK: - totalQuestions

    func testTotalQuestionsIsZeroWithNoGameState() {
        let viewModel = makeViewModel()
        XCTAssertEqual(viewModel.totalQuestions, 0)
    }

    // MARK: - currentQuestion

    func testCurrentQuestionIsNilWithNoGameState() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.currentQuestion)
    }

    // MARK: - animateOutAndAdvance

    func testAnimateOutAndAdvanceSetsTransitioningPhase() {
        let viewModel = makeViewModel()
        viewModel.phase = .revealing
        viewModel.animateOutAndAdvance()
        XCTAssertEqual(viewModel.phase, .transitioning)
    }

    func testAnimateOutAndAdvanceHidesAllCards() {
        let viewModel = makeViewModel()
        viewModel.showTitle = true
        viewModel.showCardA = true
        viewModel.showCardB = true
        viewModel.phase = .revealing
        viewModel.animateOutAndAdvance()
        XCTAssertFalse(viewModel.showTitle)
        XCTAssertFalse(viewModel.showCardA)
        XCTAssertFalse(viewModel.showCardB)
    }

    // MARK: - Phase Equatable

    func testPhaseEqualityLoading() {
        XCTAssertEqual(WMFWhichCameFirstViewModel.Phase.loading, .loading)
    }

    func testPhaseEqualityError() {
        XCTAssertEqual(
            WMFWhichCameFirstViewModel.Phase.error("something went wrong"),
            .error("something went wrong")
        )
    }

    func testPhaseInequalityErrorDifferentMessages() {
        XCTAssertNotEqual(
            WMFWhichCameFirstViewModel.Phase.error("error A"),
            .error("error B")
        )
    }

    // MARK: - RevealState

    func testRevealStateCorrect() {
        let state = WMFWhichCameFirstViewModel.RevealState(picked: "A", correct: "A", isCorrect: true)
        XCTAssertTrue(state.isCorrect)
        XCTAssertEqual(state.picked, state.correct)
    }

    func testRevealStateIncorrect() {
        let state = WMFWhichCameFirstViewModel.RevealState(picked: "B", correct: "A", isCorrect: false)
        XCTAssertFalse(state.isCorrect)
        XCTAssertNotEqual(state.picked, state.correct)
    }
}

// MARK: - LocalizedStrings

private extension WMFWhichCameFirstViewModel.LocalizedStrings {
    static var demoStrings: WMFWhichCameFirstViewModel.LocalizedStrings {
        WMFWhichCameFirstViewModel.LocalizedStrings(
            title: "Which came first?",
            submitButton: "Submit",
            nextButton: "Next",
            seeResultsButton: "See Results",
            correctFeedback: "Correct!",
            correctFeedback2: "+1 point",
            incorrectFeedback: "Incorrect",
            gameCompleteTitle: "Game Complete!",
            perfectScoreMessage: "Perfect score!",
            niceWorkMessage: "Nice work! Come back tomorrow for a new game.",
            betterLuckMessage: "Better luck tomorrow!",
            errorTitle: "Something went wrong",
            retryButton: "Retry"
        )
    }
}

// MARK: - WMFOnThisDayCardEvent Mock

private extension WMFOnThisDayCardEvent {
    static func mockEvent() -> WMFOnThisDayCardEvent {
        WMFOnThisDayCardEvent(
            text: "A historical event occurred.",
            date: Date(),
            imageURL: nil
        )
    }
}
