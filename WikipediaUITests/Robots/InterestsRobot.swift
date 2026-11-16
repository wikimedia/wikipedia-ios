import XCTest
import WMFComponents

/// Drives the interests selection screen, which appears both as a step in app onboarding and
/// as a pushed screen under Home feed settings.
struct InterestsRobot: ScreenshotCapturingRobot {
    let base: UITestRobot

    private var articleCards: XCUIElementQuery {
        base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Interests.articleCard)
    }

    private var selectedArticleCards: XCUIElementQuery {
        articleCards.matching(NSPredicate(format: "selected == true"))
    }

    private var headerTitle: XCUIElement {
        base.app.descendants(matching: .any)[AccessibilityIdentifiers.Interests.headerTitle]
    }

    private var selectedCountLabel: XCUIElement {
        base.app.descendants(matching: .any)[AccessibilityIdentifiers.Interests.selectedCount]
    }
}

// MARK: - Screen state

extension InterestsRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Interests.view).firstMatch,
            timeout: 30,
            file: file,
            line: line
        )
        return self
    }

    /// Waits for the suggested article grid, which loads from the network after the screen appears.
    @discardableResult
    func assertArticleCardsVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            articleCards.firstMatch,
            timeout: 30,
            description: "an interests article card",
            file: file,
            line: line
        )
        return self
    }

    /// Nothing is selected: the "What are you interested in?" header shows instead of a count.
    @discardableResult
    func assertNothingSelected(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(headerTitle, timeout: 10, description: "interests header title", file: file, line: line)
        base.waitForElementToDisappear(selectedCountLabel, timeout: 10, file: file, line: line)
        assertSelectedCardCount(0, file: file, line: line)
        return self
    }

    @discardableResult
    func assertSelectedCount(_ count: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(selectedCountLabel, timeout: 10, description: "interests selected count", file: file, line: line)
        let predicate = NSPredicate(format: "label CONTAINS %@", "\(count)")
        let result = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: selectedCountLabel)],
            timeout: 10
        )
        XCTAssertEqual(
            result,
            .completed,
            "Expected the selected count to show \(count) but it shows '\(selectedCountLabel.label)'.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertSelectedCardCount(_ count: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let predicate = NSPredicate { [selectedArticleCards] _, _ in
            selectedArticleCards.count == count
        }
        let result = XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)],
            timeout: 10
        )
        XCTAssertEqual(
            result,
            .completed,
            "Expected \(count) selected article cards but found \(selectedArticleCards.count).",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertCardIsSelected(at index: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertSelected(articleCards.element(boundBy: index), file: file, line: line)
        return self
    }
}

// MARK: - Selecting

extension InterestsRobot {
    @discardableResult
    func tapArticleCard(at index: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let card = articleCards.element(boundBy: index)
        base.assertVisible(card, timeout: 30, description: "interests article card \(index)", file: file, line: line)
        card.tap()
        return self
    }

    /// Interests saved by an earlier launch persist on the device and load as selected under
    /// Settings, so tests that need an empty start clear them through the screen first.
    @discardableResult
    func clearExistingSelections(file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertArticleCardsVisible(file: file, line: line)
        if selectedCountLabel.waitForExistence(timeout: 3) {
            tapDeselectAll(file: file, line: line)
        }
        return assertNothingSelected(file: file, line: line)
    }

    @discardableResult
    func tapDeselectAll(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(
            withIdentifier: AccessibilityIdentifiers.Interests.deselectAllButton,
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Search

extension InterestsRobot {
    @discardableResult
    func searchInterests(for term: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let searchField = base.app.searchFields[AccessibilityIdentifiers.Interests.searchField]
        base.assertExists(searchField, timeout: 10, file: file, line: line)
        searchField.tap()
        searchField.typeText(term)
        return self
    }

    @discardableResult
    func assertSearchResultsVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(searchResultRows.firstMatch, timeout: 10, description: "an interests search result", file: file, line: line)
        return self
    }

    @discardableResult
    func addFirstSearchResult(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let firstResult = searchResultRows.firstMatch
        base.assertExists(firstResult, timeout: 10, description: "an interests search result", file: file, line: line)
        firstResult.tap()
        return self
    }

    private var searchResultRows: XCUIElementQuery {
        base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Interests.searchResultRow)
    }
}
