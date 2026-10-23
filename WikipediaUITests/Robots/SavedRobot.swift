import XCTest
import WMFComponents

/// Represents the Saved tab: the All articles and Reading lists segments and their navigation bar.
struct SavedRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    var fixture: SavedFixture {
        guard let fixture = SavedFixture.fixture(languageCode: configuration.languageCode) else {
            preconditionFailure("SavedRobot requires a supported Saved fixture language.")
        }
        return fixture
    }
}

// MARK: - Screen state

extension SavedRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Saved.view],
            timeout: 15,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertAllArticlesEmptyStateVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            element(withIdentifier: AccessibilityIdentifiers.Saved.allArticlesEmptyView),
            timeout: 15,
            description: "All articles empty state",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertReadingListsEmptyStateVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            readingListsEmptyView,
            timeout: 15,
            description: "Reading lists empty state",
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Segments

extension SavedRobot {
    @discardableResult
    func showAllArticles(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapScopeButton(labeled: fixture.labels.allArticlesScope, file: file, line: line)
        return self
    }

    @discardableResult
    func showReadingLists(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapScopeButton(labeled: fixture.labels.readingListsScope, file: file, line: line)
        // The collection view is hidden while the segment is empty, so either surface counts.
        let predicate = NSPredicate { [readingListsCollectionView, readingListsEmptyView] _, _ in
            readingListsCollectionView.exists || readingListsEmptyView.exists
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 15),
            .completed,
            "Expected the reading lists segment to show its list or its empty state within 15 seconds.",
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - All articles rows

extension SavedRobot {
    @discardableResult
    func assertArticleRowVisible(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(articleRow(title), timeout: 15, description: "saved article row '\(title)'", file: file, line: line)
        return self
    }

    @discardableResult
    func assertArticleRowAbsent(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(articleRow(title), timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func assertArticleRowsOrdered(_ titles: [String], file: StaticString = #filePath, line: UInt = #line) -> Self {
        for title in titles {
            assertArticleRowVisible(title, file: file, line: line)
        }
        let expected = titles.map { AccessibilityIdentifiers.Saved.allArticlesRow($0) }
        let actual = base.identifiersOrderedTopToBottom(of: titles.map { articleRow($0) })
        XCTAssertEqual(actual, expected, "Expected the saved article rows in this order.", file: file, line: line)
        return self
    }

    @discardableResult
    func assertArticleRow(_ title: String, isAbove lowerTitle: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertArticleRowVisible(title, file: file, line: line)
        assertArticleRowVisible(lowerTitle, file: file, line: line)
        XCTAssertLessThan(articleRow(title).frame.minY, articleRow(lowerTitle).frame.minY, "Expected '\(title)' above '\(lowerTitle)'.", file: file, line: line)
        return self
    }

    @discardableResult
    func assertReadingListTagVisible(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(readingListTag(name), timeout: 15, description: "reading list tag '\(name)'", file: file, line: line)
        return self
    }

    @discardableResult
    func openArticleRow(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let row = articleRow(title)
        base.assertVisible(row, timeout: 15, description: "saved article row '\(title)'", file: file, line: line)
        row.tap()
        return ArticleRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openReadingListTag(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> ReadingListDetailRobot {
        let tag = readingListTag(name)
        base.assertVisible(tag, timeout: 15, description: "reading list tag '\(name)'", file: file, line: line)
        tag.tap()
        return ReadingListDetailRobot(base: base, configuration: configuration).assertVisible(named: name, file: file, line: line)
    }

    @discardableResult
    func longPressArticleRow(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let row = articleRow(title)
        base.assertVisible(row, timeout: 15, description: "saved article row '\(title)'", file: file, line: line)
        row.press(forDuration: 1.2)
        base.assertExists(
            base.menuItem(withTitle: fixture.labels.removeFromSaved),
            timeout: 5,
            description: "context menu item '\(fixture.labels.removeFromSaved)'",
            file: file,
            line: line
        )
        return self
    }

    /// The context menu preview shows the article snippet from the saved record. It must not need the network.
    /// The preview window exposes its texts as plain elements with a label, not as static texts.
    @discardableResult
    func assertContextMenuPreviewShows(_ text: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let previewText = base.app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", text)).firstMatch
        base.assertExists(
            previewText,
            timeout: 5,
            description: "context menu preview text '\(text)'",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func dismissContextMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let item = base.menuItem(withTitle: fixture.labels.removeFromSaved)
        // The preview sits at the top for a row near the top of the list, so tap the dimmed bottom edge.
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.97)).tap()
        base.waitForElementToDisappear(item, timeout: 5, file: file, line: line)
        return self
    }

    @discardableResult
    func swipeToUnsaveArticleRow(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let row = articleRow(title)
        base.assertVisible(row, timeout: 15, description: "saved article row '\(title)'", file: file, line: line)
        if configuration.isRightToLeft {
            row.swipeRight()
        } else {
            row.swipeLeft()
        }
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.rowDeleteSwipeButton, timeout: 5, file: file, line: line)
        return self
    }
}

// MARK: - Search

extension SavedRobot {
    @discardableResult
    func search(_ text: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(searchField, timeout: 15, description: "Saved search field", file: file, line: line)
        searchField.tap()
        searchField.typeText(text)
        return self
    }

    @discardableResult
    func clearSearch(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let clearButton = searchField.buttons.firstMatch
        if clearButton.waitForExistence(timeout: 2) {
            clearButton.tap()
        } else if let text = searchField.value as? String {
            searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count))
        }
        return self
    }

    @discardableResult
    func dismissSearch(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6)).tap()
        return self
    }
}

// MARK: - More menu, sorting and editing

extension SavedRobot {
    enum SortOption {
        case byTitle
        case byRecentlyAdded
    }

    @discardableResult
    func sort(by option: SortOption, file: StaticString = #filePath, line: UInt = #line) -> Self {
        openMoreMenu(file: file, line: line)
        tapMenuItem(fixture.labels.sort, file: file, line: line)
        let label: String
        switch option {
        case .byTitle:
            label = fixture.labels.sortByTitle
        case .byRecentlyAdded:
            label = fixture.labels.sortByRecentlyAdded
        }
        let sheet = base.app.sheets.firstMatch
        base.assertExists(sheet, timeout: 5, description: "sort sheet", file: file, line: line)
        let optionButton = sheet.buttons[label]
        base.assertVisible(optionButton, timeout: 5, description: "sort option '\(label)'", file: file, line: line)
        optionButton.tap()
        base.waitForElementToDisappear(sheet, timeout: 5, file: file, line: line)
        return self
    }

    @discardableResult
    func enterEditMode(file: StaticString = #filePath, line: UInt = #line) -> Self {
        openMoreMenu(file: file, line: line)
        tapMenuItem(fixture.labels.edit, file: file, line: line)
        base.assertExists(
            base.app.buttons[AccessibilityIdentifiers.Saved.editingCancelButton],
            timeout: 5,
            description: "editing cancel button",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func cancelEditMode(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.editingCancelButton, timeout: 5, file: file, line: line)
        return self
    }

    @discardableResult
    func selectArticleRow(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let row = articleRow(title)
        base.assertVisible(row, timeout: 15, description: "saved article row '\(title)'", file: file, line: line)
        row.tap()
        return self
    }

    @discardableResult
    func unsaveSelectedArticles(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.allArticlesEditingToolbarUnsaveButton, timeout: 5, file: file, line: line)
        return self
    }

    @discardableResult
    func addSelectedArticlesToList(file: StaticString = #filePath, line: UInt = #line) -> AddToReadingListRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.allArticlesEditingToolbarAddToListButton, timeout: 5, file: file, line: line)
        return AddToReadingListRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func assertUnsaveAlertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(unsaveAlert, timeout: 5, description: "unsave confirmation alert", file: file, line: line)
        return self
    }

    @discardableResult
    func confirmUnsave(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let button = unsaveAlert.buttons[fixture.labels.unsave]
        base.assertVisible(button, timeout: 5, description: "unsave alert confirm button", file: file, line: line)
        button.tap()
        base.waitForElementToDisappear(unsaveAlert, timeout: 5, file: file, line: line)
        return self
    }
}

// MARK: - Reading lists segment

extension SavedRobot {
    @discardableResult
    func assertReadingListVisible(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(readingListCell(name), timeout: 15, description: "reading list cell '\(name)'", file: file, line: line)
        return self
    }

    @discardableResult
    func assertReadingListAbsent(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(readingListCell(name), timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func assertReadingListsOrdered(_ names: [String], file: StaticString = #filePath, line: UInt = #line) -> Self {
        for name in names {
            assertReadingListVisible(name, file: file, line: line)
        }
        let expected = names.map { AccessibilityIdentifiers.Saved.readingListCell($0) }
        let actual = base.identifiersOrderedTopToBottom(of: names.map { readingListCell($0) })
        XCTAssertEqual(actual, expected, "Expected the reading list cells in this order.", file: file, line: line)
        return self
    }

    @discardableResult
    func assertReadingList(_ name: String, isAbove lowerName: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertReadingListVisible(name, file: file, line: line)
        assertReadingListVisible(lowerName, file: file, line: line)
        XCTAssertLessThan(readingListCell(name).frame.minY, readingListCell(lowerName).frame.minY, "Expected '\(name)' above '\(lowerName)'.", file: file, line: line)
        return self
    }

    @discardableResult
    func openReadingList(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> ReadingListDetailRobot {
        let cell = readingListCell(name)
        base.assertVisible(cell, timeout: 15, description: "reading list cell '\(name)'", file: file, line: line)
        cell.tap()
        return ReadingListDetailRobot(base: base, configuration: configuration).assertVisible(named: name, file: file, line: line)
    }

    @discardableResult
    func createListFromEmptyState(file: StaticString = #filePath, line: UInt = #line) -> CreateReadingListRobot {
        assertReadingListsEmptyStateVisible(file: file, line: line)
        let button = readingListsEmptyView.buttons.firstMatch
        base.assertVisible(button, timeout: 5, description: "empty state create list button", file: file, line: line)
        button.tap()
        return CreateReadingListRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    /// Swipes the cell open and taps the single swipe action, Delete.
    @discardableResult
    func swipeToDeleteReadingList(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let cell = readingListCell(name)
        base.assertVisible(cell, timeout: 15, description: "reading list cell '\(name)'", file: file, line: line)
        let frame = cell.frame
        let startX: CGFloat = configuration.isRightToLeft ? 0.15 : 0.85
        let endX: CGFloat = configuration.isRightToLeft ? 0.85 : 0.15
        let start = cell.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: 0.5))
        let end = cell.coordinate(withNormalizedOffset: CGVector(dx: endX, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
        // The revealed action sits at the trailing edge of the cell's frame.
        let actionX = configuration.isRightToLeft ? frame.minX + 36 : frame.maxX - 36
        let action = base.app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: actionX, dy: frame.midY))
        action.tap()
        return self
    }

    @discardableResult
    func selectReadingList(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let cell = readingListCell(name)
        base.assertVisible(cell, timeout: 15, description: "reading list cell '\(name)'", file: file, line: line)
        cell.tap()
        return self
    }

    @discardableResult
    func deleteSelectedReadingLists(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.batchEditToolbarButton("delete"), timeout: 5, file: file, line: line)
        return self
    }

    @discardableResult
    func assertDeleteListsAlertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(deleteListsAlert, timeout: 5, description: "delete reading lists alert", file: file, line: line)
        return self
    }

    @discardableResult
    func confirmDeleteLists(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let button = deleteListsAlert.buttons[fixture.labels.delete]
        base.assertVisible(button, timeout: 5, description: "delete lists alert confirm button", file: file, line: line)
        button.tap()
        base.waitForElementToDisappear(deleteListsAlert, timeout: 5, file: file, line: line)
        return self
    }
}

// MARK: - Navigation bar

extension SavedRobot {
    @discardableResult
    func openProfile(file: StaticString = #filePath, line: UInt = #line) -> ProfileRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Profile.button, file: file, line: line)
        return ProfileRobot(base: base).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openTabs(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Tabs.button, file: file, line: line)
        return ArticleRobot(base: base, configuration: configuration).assertTabsOverviewVisible(file: file, line: line)
    }
}

// MARK: - Private helpers

private extension SavedRobot {
    func element(withIdentifier identifier: String) -> XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func articleRow(_ title: String) -> XCUIElement {
        base.app.buttons.matching(identifier: AccessibilityIdentifiers.Saved.allArticlesRow(title)).firstMatch
    }

    /// The tag is a button nested in the row button. SwiftUI also reports the row content as a
    /// button carrying the tag's identifier, so the label picks the real tag and its own frame.
    func readingListTag(_ name: String) -> XCUIElement {
        let predicate = NSPredicate(format: "identifier == %@ AND label == %@", AccessibilityIdentifiers.Saved.readingListTag(name), name)
        return base.app.buttons.matching(predicate).firstMatch
    }

    func readingListCell(_ name: String) -> XCUIElement {
        element(withIdentifier: AccessibilityIdentifiers.Saved.readingListCell(name))
    }

    var readingListsCollectionView: XCUIElement {
        base.app.collectionViews[AccessibilityIdentifiers.Saved.readingListsView]
    }

    var readingListsEmptyView: XCUIElement {
        element(withIdentifier: AccessibilityIdentifiers.Saved.readingListsEmptyView)
    }

    var searchField: XCUIElement {
        base.app.searchFields.firstMatch
    }

    var unsaveAlert: XCUIElement {
        let identified = base.app.alerts[AccessibilityIdentifiers.Saved.unsaveArticlesAlert]
        return identified.exists ? identified : base.app.alerts.firstMatch
    }

    var deleteListsAlert: XCUIElement {
        let identified = base.app.alerts[AccessibilityIdentifiers.Saved.deleteReadingListsAlert]
        return identified.exists ? identified : base.app.alerts.firstMatch
    }

    /// The scope bar is a system segmented control with no identifiers, and its button order
    /// follows the layout direction, so the button is found by its localized title.
    func tapScopeButton(labeled title: String, file: StaticString, line: UInt) {
        let scopeBar = base.app.segmentedControls.firstMatch
        base.assertExists(scopeBar, timeout: 15, description: "Saved scope bar", file: file, line: line)
        let button = scopeBar.buttons[title]
        base.assertVisible(button, timeout: 15, description: "scope button '\(title)'", file: file, line: line)
        button.tap()
    }

    func openMoreMenu(file: StaticString, line: UInt) {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.moreButton, timeout: 15, file: file, line: line)
    }

    func tapMenuItem(_ title: String, file: StaticString, line: UInt) {
        let item = base.menuItem(withTitle: title)
        if !item.waitForExistence(timeout: 10) {
            openMoreMenu(file: file, line: line)
        }
        base.assertVisible(item, timeout: 10, description: "menu item '\(title)'", file: file, line: line)
        item.tap()
    }
}
