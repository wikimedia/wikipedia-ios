import XCTest
import WMFData
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

    func testCreateModeShowsArticlesWithoutSelection() {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        let article = WMFCreateReadingListViewModel.Article(id: "Cat", displayTitle: "Cat", project: project, description: nil, thumbnailURL: nil)
        let viewModel = WMFCreateReadingListViewModel(mode: .create, articles: [article])

        viewModel.toggleSelection(of: "Cat")

        XCTAssertFalse(viewModel.allowsArticleSelection)
        XCTAssertEqual(viewModel.articleRows.map(\.title), ["Cat"])
        XCTAssertFalse(viewModel.articleRows[0].isEditing)
        XCTAssertEqual(viewModel.selectedArticleIDs, ["Cat"])

        viewModel.name = "Birds"
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testCreateModeWithSeveralArticlesAllowsSelection() {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        let articles = ["Cat", "Dog"].map {
            WMFCreateReadingListViewModel.Article(id: $0, displayTitle: $0, project: project, description: nil, thumbnailURL: nil)
        }
        let viewModel = WMFCreateReadingListViewModel(mode: .create, articles: articles)
        viewModel.name = "Pets"

        XCTAssertTrue(viewModel.allowsArticleSelection)
        XCTAssertTrue(viewModel.articleRows.allSatisfy(\.isEditing))
        XCTAssertEqual(viewModel.selectedArticleIDs, ["Cat", "Dog"])

        viewModel.toggleSelection(of: "Cat")
        XCTAssertEqual(viewModel.selectedArticleIDs, ["Dog"])
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        viewModel.toggleSelection(of: "Dog")
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
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

    func testImportSuccessShowsArticlesAllSelected() {
        let viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)
        XCTAssertTrue(viewModel.articleRows.isEmpty)

        viewModel.importDidSucceed(articles: makeDiscoverArticles())

        XCTAssertEqual(viewModel.selectedArticleIDs, ["Cat", "Dog", "Bird"])
        XCTAssertTrue(viewModel.articleRows.allSatisfy { $0.isEditing && $0.isSelected })
        XCTAssertTrue(viewModel.isCreateButtonEnabled)

        ["Cat", "Dog", "Bird"].forEach(viewModel.toggleSelection(of:))
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testImportFailureDisablesInput() {
        let viewModel = WMFCreateReadingListViewModel(mode: .importSharedList)

        viewModel.importDidFail()

        XCTAssertFalse(viewModel.isImporting)
        XCTAssertFalse(viewModel.isInputEnabled)
        XCTAssertEqual(viewModel.name, "")
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    // MARK: - Discover mode

    private let discoverDate = Date(timeIntervalSince1970: 1_792_000_000)

    private func makeDiscoverArticles() -> [WMFCreateReadingListViewModel.Article] {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        return ["Cat", "Dog", "Bird"].map { title in
            WMFCreateReadingListViewModel.Article(id: title, displayTitle: "<i>\(title)</i>", project: project, description: nil, thumbnailURL: nil)
        }
    }

    private func makeDiscoverViewModel(validateName: ((String) -> String?)? = nil) -> WMFCreateReadingListViewModel {
        WMFCreateReadingListViewModel(mode: .saveDiscoverList(date: discoverDate), articles: makeDiscoverArticles(), validateName: validateName)
    }

    func testDiscoverModeFillsDefaultNameWithDate() {
        let viewModel = makeDiscoverViewModel()

        let formattedDate = DateFormatter.wmfShortDateShortTimeFormatter.string(from: discoverDate)
        XCTAssertEqual(viewModel.name, "Discover \(formattedDate)")
        XCTAssertNotNil(viewModel.subtitle)
        XCTAssertFalse(viewModel.focusesNameOnAppear)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testDiscoverModeSelectsAllArticlesInEditingRows() {
        let viewModel = makeDiscoverViewModel()

        XCTAssertEqual(viewModel.selectedArticleIDs, ["Cat", "Dog", "Bird"])
        XCTAssertEqual(viewModel.articleRows.map(\.title), ["Cat", "Dog", "Bird"])
        XCTAssertTrue(viewModel.articleRows.allSatisfy { $0.isEditing && $0.isSelected })
    }

    func testToggleSelectionKeepsListOrderAndSyncsRows() {
        let viewModel = makeDiscoverViewModel()

        viewModel.toggleSelection(of: "Cat")
        XCTAssertEqual(viewModel.selectedArticleIDs, ["Dog", "Bird"])
        XCTAssertFalse(viewModel.isSelected("Cat"))
        XCTAssertFalse(viewModel.articleRows[0].isSelected)

        viewModel.toggleSelection(of: "Cat")
        XCTAssertEqual(viewModel.selectedArticleIDs, ["Cat", "Dog", "Bird"])
        XCTAssertTrue(viewModel.articleRows[0].isSelected)
    }

    func testNoSelectedArticleDisablesButton() {
        let viewModel = makeDiscoverViewModel()

        ["Cat", "Dog", "Bird"].forEach(viewModel.toggleSelection(of:))
        XCTAssertTrue(viewModel.selectedArticleIDs.isEmpty)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        viewModel.toggleSelection(of: "Dog")
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }

    func testEmptyNameDisablesButtonInDiscoverMode() {
        let viewModel = makeDiscoverViewModel()

        viewModel.name = "  "

        XCTAssertNil(viewModel.nameErrorMessage)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testDuplicateDefaultNameShowsErrorOnStart() {
        let viewModel = makeDiscoverViewModel { _ in "A list with this name exists." }

        XCTAssertEqual(viewModel.nameErrorMessage, "A list with this name exists.")
        XCTAssertFalse(viewModel.isCreateButtonEnabled)
    }

    func testValidateNameRunsOnTrimmedNameWhileTyping() {
        var validatedNames: [String] = []
        let viewModel = makeDiscoverViewModel { name in
            validatedNames.append(name)
            return name == "Birds" ? "A list with this name exists." : nil
        }

        viewModel.name = " Birds "
        XCTAssertEqual(validatedNames.last, "Birds")
        XCTAssertNotNil(viewModel.nameErrorMessage)
        XCTAssertFalse(viewModel.isCreateButtonEnabled)

        viewModel.name = "Birds 2"
        XCTAssertNil(viewModel.nameErrorMessage)
        XCTAssertTrue(viewModel.isCreateButtonEnabled)
    }
}
