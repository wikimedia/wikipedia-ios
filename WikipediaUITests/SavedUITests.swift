import XCTest

/// Characterization tests for the Saved tab, written against the UIKit screens before the SwiftUI rewrite (T441442).
/// The seeded data comes from `SavedFixture`.
final class SavedUITests: XCTestCase {

    // MARK: - All articles

    func testSavedAllArticlesShowsSeededArticles() throws {
        let saved = openSaved()
        for title in fixture.allArticleTitles {
            saved.assertArticleRowVisible(title)
        }
    }

    func testSavedAllArticlesShowsEmptyStateWhenNothingIsSaved() throws {
        openSaved(seed: fixture.seedWithoutArticles)
            .assertAllArticlesEmptyStateVisible()
    }

    func testSavedAllArticlesSearchFiltersRows() throws {
        openSaved()
            .search("Zeb")
            .assertArticleRowVisible(SavedFixture.latestArticleTitle)
            .assertArticleRowAbsent(fixture.openableArticleTitle)
            .clearSearch()
            .assertArticleRowVisible(fixture.openableArticleTitle)
    }

    func testSavedAllArticlesSortsByRecentlyAdded() throws {
        openSaved()
            .sort(by: .byRecentlyAdded)
            .assertArticleRowsOrdered(fixture.allArticlesByRecentlyAdded)
    }

    func testSavedAllArticlesSortsByLocalizedTitle() throws {
        openSaved()
            .sort(by: .byTitle)
            .assertArticleRowsOrdered(fixture.allArticlesByTitle)
    }

    /// `apple` sits above `Émile Zola` under any title sort, binary or localized, and below it under "recently added".
    func testSavedAllArticlesSortSurvivesRelaunch() throws {
        openSaved()
            .sort(by: .byTitle)
            .assertArticleRow(SavedFixture.lowercaseArticleTitle, isAbove: SavedFixture.accentedArticleTitle)
        relaunchKeepingData()
            .assertArticleRow(SavedFixture.lowercaseArticleTitle, isAbove: SavedFixture.accentedArticleTitle)
    }

    func testSavedAllArticlesEditModeUnsavesArticleNotInAnyList() throws {
        openSaved(seed: fixture.seedWithoutLists)
            .enterEditMode()
            .selectArticleRow(SavedFixture.latestArticleTitle)
            .unsaveSelectedArticles()
            .assertArticleRowAbsent(SavedFixture.latestArticleTitle)
    }

    func testSavedAllArticlesEditModeAsksBeforeUnsavingArticleInLists() throws {
        openSaved()
            .enterEditMode()
            .selectArticleRow(fixture.openableArticleTitle)
            .unsaveSelectedArticles()
            .assertUnsaveAlertVisible()
            .confirmUnsave()
            .assertArticleRowAbsent(fixture.openableArticleTitle)
    }

    func testSavedAllArticlesEditModeCancelKeepsArticles() throws {
        openSaved()
            .enterEditMode()
            .selectArticleRow(SavedFixture.latestArticleTitle)
            .cancelEditMode()
            .assertArticleRowVisible(SavedFixture.latestArticleTitle)
    }

    func testSavedAllArticlesEditModeAddsArticleToList() throws {
        let saved = openSaved()
            .enterEditMode()
            .selectArticleRow(fixture.openableArticleTitle)
        saved.addSelectedArticlesToList()
            .assertReadingListVisible(SavedFixture.firstListName)
            .assertReadingListAbsent(SavedFixture.lowercaseListName)
            .chooseReadingList(SavedFixture.accentedListName)
            .assertDismissed()
        saved.assertReadingListTagVisible(SavedFixture.accentedListName)
    }

    func testSavedAllArticlesSwipeUnsavesArticle() throws {
        openSaved(seed: fixture.seedWithoutLists)
            .swipeToUnsaveArticleRow(SavedFixture.latestArticleTitle)
            .assertArticleRowAbsent(SavedFixture.latestArticleTitle)
    }

    func testSavedAllArticlesRowOpensArticle() throws {
        openSaved()
            .openArticleRow(fixture.openableArticleTitle)
            .assertLoadedArticle(named: fixture.openableArticleTitle)
            .tapBackToSaved()
            .assertArticleRowVisible(fixture.openableArticleTitle)
    }

    func testSavedAllArticlesReadingListTagOpensList() throws {
        openSaved()
            .assertReadingListTagVisible(SavedFixture.lowercaseListName)
            .openReadingListTag(SavedFixture.lowercaseListName)
            .assertArticleVisible(fixture.openableArticleTitle)
    }

    func testSavedAllArticlesLongPressShowsContextMenu() throws {
        openSaved()
            .longPressArticleRow(SavedFixture.latestArticleTitle)
            .assertContextMenuPreviewShows(SavedFixture.latestArticleSnippet)
            .dismissContextMenu()
            .assertArticleRowVisible(SavedFixture.latestArticleTitle)
    }

    func testSavedProfileButtonOpensProfile() throws {
        openSaved()
            .openProfile()
    }

    func testSavedTabsButtonOpensArticleTabs() throws {
        openSaved()
            .openTabs()
    }

    // MARK: - Reading lists

    func testSavedReadingListsShowsSeededLists() throws {
        let saved = openSaved().showReadingLists()
        for name in fixture.readingListNames {
            saved.assertReadingListVisible(name)
        }
    }

    func testSavedReadingListsEmptyStateCreatesList() throws {
        let saved = openSaved(seed: fixture.seedWithoutLists).showReadingLists()
        saved.createListFromEmptyState()
            .typeName(SavedFixture.newListName)
            .tapCreate()
            .assertDismissed()
        saved.assertReadingListVisible(SavedFixture.newListName)
    }

    func testSavedReadingListsSearchFiltersLists() throws {
        openSaved()
            .showReadingLists()
            .search("Zoo")
            .assertReadingListVisible(SavedFixture.firstListName)
            .assertReadingListAbsent(SavedFixture.lowercaseListName)
    }

    func testSavedReadingListsSortsByRecentlyAdded() throws {
        openSaved()
            .showReadingLists()
            .sort(by: .byRecentlyAdded)
            .assertReadingListsOrdered(fixture.readingListsByRecentlyAdded)
    }

    func testSavedReadingListsSortsByLocalizedTitle() throws {
        openSaved()
            .showReadingLists()
            .sort(by: .byTitle)
            .assertReadingListsOrdered(fixture.readingListsByTitle)
    }

    func testSavedReadingListsSortSurvivesRelaunch() throws {
        openSaved()
            .showReadingLists()
            .sort(by: .byRecentlyAdded)
            .assertReadingList(SavedFixture.accentedListName, isAbove: SavedFixture.lowercaseListName)
        relaunchKeepingData()
            .showReadingLists()
            .assertReadingList(SavedFixture.accentedListName, isAbove: SavedFixture.lowercaseListName)
    }

    func testSavedReadingListsCellOpensDetail() throws {
        openSaved()
            .showReadingLists()
            .openReadingList(SavedFixture.firstListName)
            .assertArticleVisible(SavedFixture.lowercaseArticleTitle)
            .assertArticleVisible(SavedFixture.accentedArticleTitle)
            .assertArticleVisible(SavedFixture.latestArticleTitle)
    }

    func testSavedReadingListsSwipeDeletesListAfterConfirmation() throws {
        openSaved()
            .showReadingLists()
            .swipeToDeleteReadingList(SavedFixture.firstListName)
            .assertDeleteListsAlertVisible()
            .confirmDeleteLists()
            .assertReadingListAbsent(SavedFixture.firstListName)
    }

    func testSavedReadingListsEditModeDeletesEmptyListWithoutConfirmation() throws {
        openSaved()
            .showReadingLists()
            .enterEditMode()
            .selectReadingList(SavedFixture.accentedListName)
            .deleteSelectedReadingLists()
            .assertReadingListAbsent(SavedFixture.accentedListName)
    }

    func testSavedReadingListsEditModeAsksBeforeDeletingListWithArticles() throws {
        openSaved()
            .showReadingLists()
            .enterEditMode()
            .selectReadingList(SavedFixture.lowercaseListName)
            .deleteSelectedReadingLists()
            .assertDeleteListsAlertVisible()
            .confirmDeleteLists()
            .assertReadingListAbsent(SavedFixture.lowercaseListName)
    }

    // MARK: - Reading list detail

    func testReadingListDetailRenamesList() throws {
        openFirstList()
            .rename(to: SavedFixture.newListName)
            .tapBackToSaved()
            .assertReadingListVisible(SavedFixture.newListName)
            .assertReadingListAbsent(SavedFixture.firstListName)
    }

    func testReadingListDetailSearchFiltersArticles() throws {
        openFirstList()
            .search("app")
            .assertArticleVisible(SavedFixture.lowercaseArticleTitle)
            .assertArticleAbsent(SavedFixture.latestArticleTitle)
    }

    func testReadingListDetailSortsByRecentlyAdded() throws {
        openFirstList()
            .sort(by: .byRecentlyAdded)
            .assertArticlesOrdered(fixture.firstListArticlesByRecentlyAdded)
    }

    func testReadingListDetailSortsByLocalizedTitle() throws {
        openFirstList()
            .sort(by: .byTitle)
            .assertArticlesOrdered(fixture.firstListArticlesByTitle)
    }

    /// Whatever order the title sort gives, the top two rows must be the same after a relaunch,
    /// and they differ from the "recently added" default.
    func testReadingListDetailSortSurvivesRelaunch() throws {
        let titles = fixture.firstListArticlesByTitle
        let topTwoBeforeRelaunch = openFirstList()
            .sort(by: .byTitle)
            .topArticleTitles(among: titles, count: 2)
        XCTAssertNotEqual(topTwoBeforeRelaunch, Array(fixture.firstListArticlesByRecentlyAdded.prefix(2)), "The title sort must change the order.")
        relaunchKeepingData()
            .showReadingLists()
            .openReadingList(SavedFixture.firstListName)
            .assertTopArticles(topTwoBeforeRelaunch, among: titles)
    }

    func testReadingListDetailEditModeRemovesArticle() throws {
        openFirstList()
            .enterEditMode()
            .selectArticle(SavedFixture.latestArticleTitle)
            .removeSelectedArticles()
            .assertArticleAbsent(SavedFixture.latestArticleTitle)
    }

    func testReadingListDetailEditModeMovesArticleToAnotherList() throws {
        let detail = openFirstList()
            .enterEditMode()
            .selectArticle(SavedFixture.latestArticleTitle)
        detail.moveSelectedArticlesToList()
            .assertReadingListAbsent(SavedFixture.firstListName)
            .chooseReadingList(SavedFixture.lowercaseListName)
            .assertDismissed()
        detail.assertArticleAbsent(SavedFixture.latestArticleTitle)
            .tapBackToSaved()
            .openReadingList(SavedFixture.lowercaseListName)
            .assertArticleVisible(SavedFixture.latestArticleTitle)
    }

    func testReadingListDetailEditModeAddsArticleToAnotherList() throws {
        let detail = openFirstList()
            .enterEditMode()
            .selectArticle(SavedFixture.lowercaseArticleTitle)
        detail.addSelectedArticlesToList()
            .assertReadingListAbsent(SavedFixture.firstListName)
            .assertReadingListVisible(SavedFixture.lowercaseListName)
            .chooseReadingList(SavedFixture.accentedListName)
            .assertDismissed()
        detail.assertArticleVisible(SavedFixture.lowercaseArticleTitle)
            .tapBackToSaved()
            .openReadingList(SavedFixture.accentedListName)
            .assertArticleVisible(SavedFixture.lowercaseArticleTitle)
    }

    func testReadingListDetailCreateNewListFromAddSheetAddsArticle() throws {
        let detail = openFirstList()
            .enterEditMode()
            .selectArticle(SavedFixture.latestArticleTitle)
        detail.addSelectedArticlesToList()
            .createNewList(named: SavedFixture.newListName)
        detail.tapBackToSaved()
            .openReadingList(SavedFixture.newListName)
            .assertArticleVisible(SavedFixture.latestArticleTitle)
    }

    func testReadingListDetailArticleCellOpensArticle() throws {
        openSaved()
            .showReadingLists()
            .openReadingList(SavedFixture.lowercaseListName)
            .openArticle(fixture.openableArticleTitle)
            .assertLoadedArticle(named: fixture.openableArticleTitle)
            .tapBackToReadingListDetail()
            .assertArticleVisible(fixture.openableArticleTitle)
    }

    func testReadingListDetailShowsEmptyStateForEmptyList() throws {
        openSaved()
            .showReadingLists()
            .openReadingList(SavedFixture.accentedListName)
            .assertEmptyStateVisible()
    }

    // MARK: - Create list form

    func testCreateReadingListButtonIsDisabledUntilNameIsTyped() throws {
        openSaved(seed: fixture.seedWithoutLists)
            .showReadingLists()
            .createListFromEmptyState()
            .assertCreateButtonEnabled(false)
            .typeName(SavedFixture.newListName)
            .assertCreateButtonEnabled(true)
            .close()
    }

    func testCreateReadingListRejectsDuplicateName() throws {
        openSaved()
            .enterEditMode()
            .selectArticleRow(fixture.openableArticleTitle)
            .addSelectedArticlesToList()
            .createNewList()
            .typeName(SavedFixture.firstListName)
            .tapCreate()
            .assertNameErrorVisible()
            .assertCreateButtonEnabled(false)
    }

    // MARK: - Helpers

    private var fixture: SavedFixture {
        guard let fixture = SavedFixture.fixture(languageCode: uiTestConfiguration.languageCode) else {
            preconditionFailure("SavedUITests requires a supported Saved fixture language.")
        }
        return fixture
    }

    private func openSaved(seed: UITestReadingListsSeed? = nil, file: StaticString = #filePath, line: UInt = #line) -> SavedRobot {
        launchWikipediaAppRobot(onboardingState: .completed, readingListsSeed: seed ?? fixture.seed)
            .home
            .assertVisible(file: file, line: line)
            .openSaved(file: file, line: line)
    }

    private func openFirstList(file: StaticString = #filePath, line: UInt = #line) -> ReadingListDetailRobot {
        openSaved(file: file, line: line)
            .showReadingLists(file: file, line: line)
            .openReadingList(SavedFixture.firstListName, file: file, line: line)
    }

    /// Terminates the app and launches it again without a seed, so the data on device is kept.
    private func relaunchKeepingData(file: StaticString = #filePath, line: UInt = #line) -> SavedRobot {
        XCUIApplication().terminate()
        return launchWikipediaAppRobot(onboardingState: .completed, readingListsSeed: nil)
            .home
            .assertVisible(file: file, line: line)
            .openSaved(file: file, line: line)
    }
}
