import XCTest
@testable import WMFComponents

@MainActor
final class WMFChooseEditorViewModelTests: XCTestCase {

    func testInitialStateDefaultsToVisualAndUncheckedCheckbox() {
        let viewModel = WMFChooseEditorViewModel(didTapContinue: { _, _ in }, didTapClose: {})
        XCTAssertEqual(viewModel.selectedMode, .visual)
        XCTAssertFalse(viewModel.dontShowAgain)
    }

    func testInitRespectsInitialMode() {
        let viewModel = WMFChooseEditorViewModel(initialMode: .source, didTapContinue: { _, _ in }, didTapClose: {})
        XCTAssertEqual(viewModel.selectedMode, .source)
    }

    func testTappedContinuePassesSelectionAndCheckboxState() {
        var receivedMode: WMFChooseEditorViewModel.EditMode?
        var receivedDontShowAgain: Bool?
        let viewModel = WMFChooseEditorViewModel(didTapContinue: { mode, dontShowAgain in
            receivedMode = mode
            receivedDontShowAgain = dontShowAgain
        }, didTapClose: {})

        viewModel.selectedMode = .source
        viewModel.dontShowAgain = true
        viewModel.tappedContinue()

        XCTAssertEqual(receivedMode, .source)
        XCTAssertEqual(receivedDontShowAgain, true)
    }

    func testTappedCloseFiresClosure() {
        var closed = false
        let viewModel = WMFChooseEditorViewModel(didTapContinue: { _, _ in }, didTapClose: { closed = true })
        viewModel.tappedClose()
        XCTAssertTrue(closed)
    }
}
