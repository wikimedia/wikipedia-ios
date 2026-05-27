import XCTest
import WMFComponents

/// Represents an article screen and its top navigation controls.
struct ArticleRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration
    private let systemBackButtonIdentifier = "BackButton"

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
        base.assertVisible(navigationBar.buttons.firstMatch, timeout: 15, description: "article navigation button", file: file, line: line)
        let backButton = backButton(in: navigationBar)
        base.assertExists(backButton, timeout: 15, description: "article back button", file: file, line: line)
        XCTAssertFalse(backButton.frame.isEmpty, "Expected article back button to have a tappable frame.", file: file, line: line)
        backButton.tap()
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
        return SearchRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openLeadImageGallery(file: StaticString = #filePath, line: UInt = #line) -> ImageGalleryRobot {
        let leadImage = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Article.leadImage)
            .firstMatch
        base.assertExists(leadImage, timeout: 30, description: "article lead image", file: file, line: line)
        leadImage.tap()
        return ImageGalleryRobot(base: base)
            .assertVisible(file: file, line: line)
    }

    private var homeButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.homeButton]
    }

    private var searchButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.searchButton]
    }

    private func backButton(in navigationBar: XCUIElement) -> XCUIElement {
        let systemBackButton = navigationBar.buttons.matching(identifier: systemBackButtonIdentifier).firstMatch
        if systemBackButton.exists {
            return systemBackButton
        }

        let buttons = navigationBar.buttons.allElementsBoundByIndex
            .filter { $0.exists && !$0.frame.isEmpty }
            .sorted { $0.frame.midX < $1.frame.midX }

        // Some simulator versions do not expose the system back button identifier.
        // Select the visually leading navigation-bar button instead of relying on query order.
        return (configuration.isRightToLeft ? buttons.last : buttons.first) ?? navigationBar.buttons.firstMatch
    }

    private func navigationBar(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let navigationBar = base.app.navigationBars.firstMatch
        base.assertExists(navigationBar, description: "article navigation bar", file: file, line: line)
        return navigationBar
    }
}
