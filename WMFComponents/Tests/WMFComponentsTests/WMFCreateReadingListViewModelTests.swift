import XCTest
@testable import WMFComponents

@MainActor
final class WMFCreateReadingListViewModelTests: XCTestCase {

    // MARK: - Create mode

    func testCreateModeStartsWithEmptyFormAndDisabledButton() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)

        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.description, "")
        XCTAssertNil(viewModel.nameErrorMessage)
        XCTAssertFalse(viewModel.isImporting)
        XCTAssertTrue(viewModel.isInputEnabled)
        XCTAssertTrue(viewModel.focusesNameOnAppear)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testCreateButtonEnablesOnlyWithNonWhitespaceName() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)

        viewModel.name = "   "
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        viewModel.name = " Birds "
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        viewModel.name = ""
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testTapCreateTrimsNameAndDescription() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)
        var received: (name: String, description: String)?
        viewModel.didTapCreate = { name, description in
            received = (name, description)
        }

        viewModel.name = "  Birds "
        viewModel.description = " Feathered animals  "
        viewModel.tapCreate()

        XCTAssertEqual(received?.name, "Birds")
        XCTAssertEqual(received?.description, "Feathered animals")
    }

    func testTapCreateDoesNothingWhileButtonIsDisabled() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)
        var callCount = 0
        viewModel.didTapCreate = { _, _ in callCount += 1 }

        viewModel.tapCreate()

        XCTAssertEqual(callCount, 0)
    }

    func testNameErrorDisablesButtonUntilNameChanges() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)
        viewModel.name = "Birds"

        viewModel.showNameError("A list with this name exists.")

        XCTAssertEqual(viewModel.nameErrorMessage, "A list with this name exists.")
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        viewModel.name = "Birds"
        XCTAssertNotNil(viewModel.nameErrorMessage, "The same name keeps the error.")

        viewModel.name = "Bird"
        XCTAssertNil(viewModel.nameErrorMessage)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testIsCreatingDisablesButton() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)
        viewModel.name = "Birds"

        viewModel.isCreating = true
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        viewModel.isCreating = false
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testTapCloseCallsClosure() {
        let viewModel = WMFCreateReadingListViewModel(mode: .create)
        var didClose = false
        viewModel.didTapClose = { didClose = true }

        viewModel.tapClose()

        XCTAssertTrue(didClose)
    }

    // MARK: - Import mode

    func testImportModeStartsImportingWithDisabledButton() {
        let viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)

        XCTAssertTrue(viewModel.isImporting)
        XCTAssertFalse(viewModel.focusesNameOnAppear)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
        XCTAssertNotEqual(viewModel.title, WMFCreateReadingListViewModel(mode: .create).title)
    }

    func testImportSuccessFillsDefaultNameAndEnablesButton() {
        let viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)

        viewModel.importDidSucceed()

        XCTAssertFalse(viewModel.isImporting)
        XCTAssertEqual(viewModel.name, "My Reading List")
        XCTAssertTrue(viewModel.isInputEnabled)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testImportFailureDisablesInput() {
        let viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)

        viewModel.importDidFail()

        XCTAssertFalse(viewModel.isImporting)
        XCTAssertFalse(viewModel.isInputEnabled)
        XCTAssertEqual(viewModel.name, "")
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }
}
