import XCTest
import WMFComponents

/// Represents one reading list: its editable header and its article list.
struct ReadingListDetailRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    private var fixture: SavedFixture {
        guard let fixture = SavedFixture.fixture(languageCode: configuration.languageCode) else {
            preconditionFailure("ReadingListDetailRobot requires a supported Saved fixture language.")
        }
        return fixture
    }
}

// MARK: - Screen state

extension ReadingListDetailRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(detailView, timeout: 15, description: "reading list detail view", file: file, line: line)
        return self
    }

    @discardableResult
    func assertVisible(named name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertVisible(file: file, line: line)
        return assertTitle(name, file: file, line: line)
    }

    @discardableResult
    func assertTitle(_ name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(titleTextField, timeout: 15, description: "reading list title field", file: file, line: line)
        let predicate = NSPredicate(format: "value == %@", name)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: titleTextField)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 10),
            .completed,
            "Expected the reading list title field to read '\(name)', got '\(titleTextField.value ?? "")'.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertArticleVisible(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(articleCell(title), timeout: 15, description: "reading list article cell '\(title)'", file: file, line: line)
        return self
    }

    @discardableResult
    func assertArticleAbsent(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(articleCell(title), timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func assertArticlesOrdered(_ titles: [String], file: StaticString = #filePath, line: UInt = #line) -> Self {
        for title in titles {
            assertArticleVisible(title, file: file, line: line)
        }
        let expected = titles.map { AccessibilityIdentifiers.ReadingListDetail.articleCell($0) }
        let actual = base.identifiersOrderedTopToBottom(of: titles.map { articleCell($0) })
        XCTAssertEqual(actual, expected, "Expected the reading list article cells in this order.", file: file, line: line)
        return self
    }

    @discardableResult
    func assertArticle(_ title: String, isAbove lowerTitle: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertArticleVisible(title, file: file, line: line)
        assertArticleVisible(lowerTitle, file: file, line: line)
        XCTAssertLessThan(articleCell(title).frame.minY, articleCell(lowerTitle).frame.minY, "Expected '\(title)' above '\(lowerTitle)'.", file: file, line: line)
        return self
    }

    /// The titles of the topmost `count` article cells among the given titles, in screen order.
    func topArticleTitles(among titles: [String], count: Int, file: StaticString = #filePath, line: UInt = #line) -> [String] {
        for title in titles.prefix(count) {
            assertArticleVisible(title, file: file, line: line)
        }
        let ordered = base.identifiersOrderedTopToBottom(of: titles.map { articleCell($0) })
        return Array(ordered.prefix(count)).compactMap { identifier in
            titles.first { AccessibilityIdentifiers.ReadingListDetail.articleCell($0) == identifier }
        }
    }

    @discardableResult
    func assertTopArticles(_ expected: [String], among titles: [String], file: StaticString = #filePath, line: UInt = #line) -> Self {
        let actual = topArticleTitles(among: titles, count: expected.count, file: file, line: line)
        XCTAssertEqual(actual, expected, "Expected these article cells at the top of the list.", file: file, line: line)
        return self
    }

    @discardableResult
    func assertEmptyStateVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            element(withIdentifier: AccessibilityIdentifiers.ReadingListDetail.emptyView),
            timeout: 15,
            description: "reading list empty state",
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Header

extension ReadingListDetailRobot {
    /// Clears the title with the field's clear button, types the new name and confirms with Return.
    @discardableResult
    func rename(to name: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(titleTextField, timeout: 15, description: "reading list title field", file: file, line: line)
        titleTextField.tap()
        let clearButton = titleTextField.buttons.firstMatch
        if clearButton.waitForExistence(timeout: 2) {
            clearButton.tap()
        } else if let text = titleTextField.value as? String {
            titleTextField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count))
        }
        titleTextField.typeText(name + "\n")
        return assertTitle(name, file: file, line: line)
    }
}

// MARK: - Search and sorting

extension ReadingListDetailRobot {
    @discardableResult
    func search(_ text: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let searchField = base.app.searchFields.firstMatch
        base.assertVisible(searchField, timeout: 15, description: "reading list search field", file: file, line: line)
        searchField.tap()
        searchField.typeText(text)
        return self
    }

    @discardableResult
    func sort(by option: SavedRobot.SortOption, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.ReadingListDetail.sortButton, timeout: 15, file: file, line: line)
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
}

// MARK: - Batch editing

extension ReadingListDetailRobot {
    @discardableResult
    func enterEditMode(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.ReadingListDetail.editButton, timeout: 15, file: file, line: line)
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
    func selectArticle(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let cell = articleCell(title)
        base.assertVisible(cell, timeout: 15, description: "reading list article cell '\(title)'", file: file, line: line)
        cell.tap()
        return self
    }

    @discardableResult
    func removeSelectedArticles(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.batchEditToolbarButton("remove"), timeout: 5, file: file, line: line)
        return self
    }

    @discardableResult
    func addSelectedArticlesToList(file: StaticString = #filePath, line: UInt = #line) -> AddToReadingListRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.batchEditToolbarButton("addTo"), timeout: 5, file: file, line: line)
        return AddToReadingListRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func moveSelectedArticlesToList(file: StaticString = #filePath, line: UInt = #line) -> AddToReadingListRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Saved.batchEditToolbarButton("moveTo"), timeout: 5, file: file, line: line)
        return AddToReadingListRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }
}

// MARK: - Navigation

extension ReadingListDetailRobot {
    @discardableResult
    func openArticle(_ title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let cell = articleCell(title)
        base.assertVisible(cell, timeout: 15, description: "reading list article cell '\(title)'", file: file, line: line)
        cell.tap()
        return ArticleRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapBackToSaved(file: StaticString = #filePath, line: UInt = #line) -> SavedRobot {
        let navigationBar = base.app.navigationBars.firstMatch
        base.assertExists(navigationBar, timeout: 10, description: "reading list navigation bar", file: file, line: line)
        let backButton = base.backButton(in: navigationBar, isRightToLeft: configuration.isRightToLeft)
        base.assertVisible(backButton, timeout: 10, description: "reading list back button", file: file, line: line)
        base.tapCenter(of: backButton, file: file, line: line)
        base.waitForElementToDisappear(detailView, timeout: 10, file: file, line: line)
        return SavedRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }
}

// MARK: - Private helpers

private extension ReadingListDetailRobot {
    func element(withIdentifier identifier: String) -> XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    var detailView: XCUIElement {
        base.app.otherElements[AccessibilityIdentifiers.ReadingListDetail.view]
    }

    var titleTextField: XCUIElement {
        base.app.textFields[AccessibilityIdentifiers.ReadingListDetail.titleTextField]
    }

    func articleCell(_ title: String) -> XCUIElement {
        element(withIdentifier: AccessibilityIdentifiers.ReadingListDetail.articleCell(title))
    }
}
