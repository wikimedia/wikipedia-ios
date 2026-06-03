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

    private func recentSearchTerm(_ searchTerm: String) -> XCUIElement {
        base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Search.recentSearchTerm(searchTerm))
            .firstMatch
    }

    private var searchField: XCUIElement {
        base.app.searchFields[AccessibilityIdentifiers.Search.searchField]
    }

    private func button(withIdentifier identifier: String, fallbackIdentifier: String?) -> XCUIElement {
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

    private func waitForSearchResult(
        named title: String,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifier = AccessibilityIdentifiers.Search.result(title)
        let identifiedResult = base.app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
        let labelledResult = base.app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, "\(title),"))
            .firstMatch

        let predicate = NSPredicate { _, _ in
            identifiedResult.exists || labelledResult.exists
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

        return identifiedResult.exists ? identifiedResult : labelledResult
    }
}
