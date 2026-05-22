import XCTest
import WMFComponents

/// Represents the Explore tab after app launch or onboarding dismissal.
struct ExploreRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Explore.view],
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func openFirstArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let articleCell = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Explore.articleCell)
            .firstMatch
        base.assertVisible(
            articleCell,
            timeout: 30,
            description: "Explore article cell",
            file: file,
            line: line
        )
        articleCell.tap()
        return ArticleRobot(base: base, configuration: configuration)
            .assertVisible(file: file, line: line)
            .assertTopControlsVisible(file: file, line: line)
    }

    @discardableResult
    func openPictureOfTheDay(file: StaticString = #filePath, line: UInt = #line) -> ImageGalleryRobot {
        let collectionView = base.app.collectionViews.firstMatch
        let pictureOfTheDayCell = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Explore.pictureOfTheDayCell)
            .firstMatch

        for _ in 0..<10 where !pictureOfTheDayCell.exists || !pictureOfTheDayCell.isHittable {
            base.dragUp(collectionView)
        }

        base.assertVisible(
            pictureOfTheDayCell,
            timeout: 10,
            description: "Explore Picture of the Day cell",
            file: file,
            line: line
        )
        pictureOfTheDayCell.tap()
        return ImageGalleryRobot(base: base).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openSearch(file: StaticString = #filePath, line: UInt = #line) -> SearchRobot {
        let identifiedButton = base.app.tabBars.buttons[AccessibilityIdentifiers.Search.tabButton]
        let searchButton = identifiedButton.waitForExistence(timeout: 5)
            ? identifiedButton
            : base.app.tabBars.buttons["Search"]
        base.assertVisible(searchButton, timeout: 15, description: "Search tab button", file: file, line: line)
        searchButton.tap()
        return SearchRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openProfile(file: StaticString = #filePath, line: UInt = #line) -> ProfileRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Profile.button, file: file, line: line)
        return ProfileRobot(base: base).assertVisible(file: file, line: line)
    }
}
