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
            base.app.searchFields[AccessibilityIdentifiers.Search.searchField],
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func openArticle(named title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let searchField = base.app.searchFields[AccessibilityIdentifiers.Search.searchField]
        base.assertVisible(searchField, timeout: 15, description: "search field", file: file, line: line)
        searchField.tap()
        searchField.typeText(title)

        let result = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Search.result(title))
            .firstMatch
        base.assertVisible(result, timeout: 30, description: "search result for \(title)", file: file, line: line)
        result.tap()

        return ArticleRobot(base: base, configuration: configuration)
            .assertVisible(file: file, line: line)
            .assertTopControlsVisible(file: file, line: line)
    }
}
