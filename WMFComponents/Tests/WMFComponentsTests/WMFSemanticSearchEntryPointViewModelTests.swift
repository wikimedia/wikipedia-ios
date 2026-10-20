import XCTest
@testable import WMFComponents

@MainActor
final class WMFSemanticSearchEntryPointViewModelTests: XCTestCase {

    private final class Recorder {
        var tapped: [String] = []
        var infoShown: [String] = []
        var hidden: [String] = []
    }

    private func makeViewModel(query: String, showsTryItNow: Bool = true, recorder: Recorder) -> WMFSemanticSearchEntryPointViewModel {
        WMFSemanticSearchEntryPointViewModel(
            query: query,
            languageCode: "en",
            showsTryItNow: showsTryItNow,
            tapAction: { recorder.tapped.append($0) },
            infoAction: { recorder.infoShown.append($0) },
            hideAction: { recorder.hidden.append($0) })
    }

    func testUpdateQueryChangesTheQuery() {
        let viewModel = makeViewModel(query: "tim", recorder: Recorder())

        viewModel.update(query: "tim cook")

        XCTAssertEqual(viewModel.query, "tim cook")
    }

    func testTapKeepsTryItNowForTheCurrentSession() {
        let recorder = Recorder()
        let viewModel = makeViewModel(query: "tim cook", showsTryItNow: true, recorder: recorder)

        viewModel.tap()

        XCTAssertTrue(viewModel.showsTryItNow)
        XCTAssertEqual(recorder.tapped, ["tim cook"])
    }

    func testTryItNowStaysHiddenWhenTheHostSaysSo() {
        let viewModel = makeViewModel(query: "tim cook", showsTryItNow: false, recorder: Recorder())

        XCTAssertFalse(viewModel.showsTryItNow)
    }

    func testActionsForwardTheCurrentQuery() {
        let recorder = Recorder()
        let viewModel = makeViewModel(query: "tim", recorder: recorder)
        viewModel.update(query: "tim cook")

        viewModel.tap()
        viewModel.showInfo()
        viewModel.hide()

        XCTAssertEqual(recorder.tapped, ["tim cook"])
        XCTAssertEqual(recorder.infoShown, ["tim cook"])
        XCTAssertEqual(recorder.hidden, ["tim cook"])
    }
}
