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
    func openProfile(file: StaticString = #filePath, line: UInt = #line) -> ProfileRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Profile.button, file: file, line: line)
        return ProfileRobot(base: base).assertVisible(file: file, line: line)
    }
}
