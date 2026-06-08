import XCTest
import WMFComponents

/// Represents the standalone article search screen.
struct SearchRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }
}

// MARK: - Screen state

extension SearchRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Search.view],
            file: file,
            line: line
        )
        base.assertExists(
            searchField,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertSearchFieldVisible(
        description: String = "search field",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        base.assertVisible(searchField, timeout: 15, description: description, file: file, line: line)
        return self
    }
}

// MARK: - Search entry

extension SearchRobot {
    @discardableResult
    func focusSearchField(file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertSearchFieldVisible(file: file, line: line)
        searchField.tap()
        return self
    }

    @discardableResult
    func typeSearchTerm(_ searchTerm: String) -> Self {
        searchField.typeText(searchTerm)
        return self
    }

    @discardableResult
    func typeSearchTermOneCharacterAtATime(_ searchTerm: String) -> Self {
        for character in searchTerm {
            searchField.typeText(String(character))
        }
        return self
    }
}

// MARK: - Search results

extension SearchRobot {
    @discardableResult
    func assertSearchResultVisible(
        named title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        _ = waitForSearchResult(named: title, file: file, line: line)
        return self
    }

    @discardableResult
    func openResult(named title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let result = waitForSearchResult(named: title, file: file, line: line)
        if result.isHittable {
            result.tap()
        } else {
            result.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        return ArticleRobot(base: base, configuration: configuration)
    }
}

// MARK: - Recent searches

extension SearchRobot {
    @discardableResult
    func assertRecentSearchTermVisible(
        _ searchTerm: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        base.assertExists(
            base.app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.Search.recentSearchesView)
                .firstMatch,
            timeout: 10,
            description: "recent searches view",
            file: file,
            line: line
        )
        base.assertVisible(
            recentSearchTerm(searchTerm),
            timeout: 10,
            description: "recent search term \(searchTerm)",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func tapClearRecentSearches(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let clearButton = button(
            withIdentifier: AccessibilityIdentifiers.Search.clearRecentSearchesButton,
            fallbackIdentifier: AccessibilityIdentifiers.Search.recentSearchesView
        )
        base.assertVisible(
            clearButton,
            timeout: 15,
            description: "clear recent searches button",
            file: file,
            line: line
        )
        clearButton.tap()
        return self
    }

    @discardableResult
    func confirmClearRecentSearches(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let confirmButton = button(
            withIdentifier: AccessibilityIdentifiers.Search.clearRecentSearchesConfirmButton,
            fallbackIdentifier: nil
        )
        base.assertVisible(
            confirmButton,
            timeout: 15,
            description: "clear recent searches confirmation button",
            file: file,
            line: line
        )
        confirmButton.tap()
        return self
    }

    @discardableResult
    func assertRecentSearchTermCleared(
        _ searchTerm: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        base.waitForElementToDisappear(
            recentSearchTerm(searchTerm),
            timeout: 10,
            file: file,
            line: line
        )
        return self
    }
}

// MARK: - Private helpers

private extension SearchRobot {
    func recentSearchTerm(_ searchTerm: String) -> XCUIElement {
        base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Search.recentSearchTerm(searchTerm))
            .firstMatch
    }

    var searchField: XCUIElement {
        base.app.searchFields[AccessibilityIdentifiers.Search.searchField]
    }

    func button(withIdentifier identifier: String, fallbackIdentifier: String?) -> XCUIElement {
        let identifiedButton = base.app.buttons.matching(identifier: identifier).firstMatch
        if identifiedButton.waitForExistence(timeout: 2) {
            return identifiedButton
        }

        if let fallbackIdentifier {
            let fallbackButton = base.app.buttons.matching(identifier: fallbackIdentifier).firstMatch
            if fallbackButton.waitForExistence(timeout: 2) {
                return fallbackButton
            }
        }

        return identifiedButton
    }

    func waitForSearchResult(
        named title: String,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifier = AccessibilityIdentifiers.Search.result(title)
        let query = base.app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@ OR label == %@ OR label BEGINSWITH %@", identifier, title, "\(title),"))

        var matchedResult: XCUIElement?
        let predicate = NSPredicate { _, _ in
            matchedResult = query.allElementsBoundByIndex.first { element in
                element.exists
            }
            return matchedResult != nil
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Expected search result for \(title) to exist within \(timeout) seconds.",
            file: file,
            line: line
        )

        return matchedResult ?? query.firstMatch
    }
}
