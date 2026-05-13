import XCTest
import WMFComponents

/// Represents an article screen and its top navigation controls.
struct ArticleRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Article.view],
            timeout: 10,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertTopControlsVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            navigationBar(file: file, line: line),
            description: "article navigation bar",
            file: file,
            line: line
        )
        base.assertExists(homeButton, description: "article W home button", file: file, line: line)
        base.assertExists(searchButton, description: "article search button", file: file, line: line)
        return self
    }

    @discardableResult
    func tapBackToExplore(file: StaticString = #filePath, line: UInt = #line) -> ExploreRobot {
        let navigationBar = navigationBar(file: file, line: line)
        let leadingOffset = configuration.isRightToLeft ? 0.93 : 0.07
        navigationBar.coordinate(withNormalizedOffset: CGVector(dx: leadingOffset, dy: 0.5)).tap()
        return ExploreRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapHomeButtonToExplore(file: StaticString = #filePath, line: UInt = #line) -> ExploreRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.homeButton, file: file, line: line)
        return ExploreRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapSearch(file: StaticString = #filePath, line: UInt = #line) -> SearchRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.searchButton, file: file, line: line)
        return SearchRobot(base: base).assertVisible(file: file, line: line)
    }

    private var homeButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.homeButton]
    }

    private var searchButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.searchButton]
    }

    private func navigationBar(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let navigationBar = base.app.navigationBars.firstMatch
        base.assertExists(navigationBar, description: "article navigation bar", file: file, line: line)
        return navigationBar
    }
}
