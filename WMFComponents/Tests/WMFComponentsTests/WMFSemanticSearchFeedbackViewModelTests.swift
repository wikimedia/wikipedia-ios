import XCTest
@testable import WMFComponents

@MainActor
final class WMFSemanticSearchFeedbackViewModelTests: XCTestCase {

    private final class Submissions: @unchecked Sendable {
        var values: [(WMFSemanticSearchFeedbackViewModel.Rating, String?)] = []
    }

    private func makeViewModel(style: WMFSemanticSearchFeedbackViewModel.Style, submissions: Submissions = Submissions()) -> WMFSemanticSearchFeedbackViewModel {
        WMFSemanticSearchFeedbackViewModel(style: style, submitAction: { rating, text in
            submissions.values.append((rating, text))
        })
    }

    func testInlineShowsTheTextFieldOnceRated() {
        let viewModel = makeViewModel(style: .inline)
        XCTAssertFalse(viewModel.isTextFieldVisible)

        viewModel.rate(.positive)

        XCTAssertTrue(viewModel.isTextFieldVisible)
    }

    func testTextStopsAtTheLimit() {
        let viewModel = makeViewModel(style: .card)

        viewModel.text = String(repeating: "a", count: WMFSemanticSearchFeedbackViewModel.textLimit + 5)

        XCTAssertEqual(viewModel.text.count, WMFSemanticSearchFeedbackViewModel.textLimit)
    }

    func testCardShowsTheTextFieldRightAway() {
        let viewModel = makeViewModel(style: .card)

        XCTAssertTrue(viewModel.isTextFieldVisible)
    }

    func testSubmitNeedsARating() {
        let submissions = Submissions()
        let viewModel = makeViewModel(style: .card, submissions: submissions)
        viewModel.text = "Pas mal"

        XCTAssertFalse(viewModel.canSubmit)
        viewModel.submit()

        XCTAssertTrue(submissions.values.isEmpty)
    }

    func testSubmitForwardsTheRatingAndTheTrimmedText() {
        let submissions = Submissions()
        let viewModel = makeViewModel(style: .inline, submissions: submissions)

        viewModel.rate(.negative)
        viewModel.text = "  Wrong passages \n"
        viewModel.submit()

        XCTAssertEqual(submissions.values.count, 1)
        XCTAssertEqual(submissions.values.first?.0, .negative)
        XCTAssertEqual(submissions.values.first?.1, "Wrong passages")
    }

    func testBlankTextIsSentAsNoText() {
        let submissions = Submissions()
        let viewModel = makeViewModel(style: .inline, submissions: submissions)

        viewModel.rate(.positive)
        viewModel.text = "   "
        viewModel.submit()

        XCTAssertEqual(submissions.values.count, 1)
        XCTAssertNil(submissions.values.first?.1)
    }
}
