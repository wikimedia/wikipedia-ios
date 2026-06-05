import XCTest
import WMFComponents

/// Represents the Explore tab after app launch or onboarding dismissal.
struct ExploreRobot: ScreenshotCapturingRobot {
    enum RootTab {
        case activity
        case explore
        case places
        case saved
        case search

        var accessibilityIdentifier: String {
            switch self {
            case .activity:
                return AccessibilityIdentifiers.RootTab.activityButton
            case .explore:
                return AccessibilityIdentifiers.RootTab.exploreButton
            case .places:
                return AccessibilityIdentifiers.RootTab.placesButton
            case .saved:
                return AccessibilityIdentifiers.RootTab.savedButton
            case .search:
                return AccessibilityIdentifiers.RootTab.searchButton
            }
        }

        var description: String {
            switch self {
            case .activity:
                return "Activity root tab"
            case .explore:
                return "Explore root tab"
            case .places:
                return "Places root tab"
            case .saved:
                return "Saved root tab"
            case .search:
                return "Search root tab"
            }
        }

        var index: Int {
            switch self {
            case .explore:
                return 0
            case .places:
                return 1
            case .saved:
                return 2
            case .activity:
                return 3
            case .search:
                return 4
            }
        }
    }

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
        let articleCells = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Explore.articleCell)
        let articleCell = base.firstHittableElement(
            matching: articleCells,
            timeout: 60,
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
    func openSearch(file: StaticString = #filePath, line: UInt = #line) -> SearchRobot {
        let identifiedButton = rootTabButton(for: .search)
        let searchButton = identifiedButton.waitForExistence(timeout: 5)
            ? identifiedButton
            : searchTabButtonFallback()
        base.assertVisible(searchButton, timeout: 15, description: "Search tab button", file: file, line: line)
        searchButton.tap()
        return SearchRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openTabs(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Tabs.button, file: file, line: line)
        return ArticleRobot(base: base, configuration: configuration)
            .assertTabsOverviewVisible(file: file, line: line)
    }

    @discardableResult
    func openProfile(file: StaticString = #filePath, line: UInt = #line) -> ProfileRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Profile.button, file: file, line: line)
        return ProfileRobot(base: base).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapRootTab(_ tab: RootTab, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let identifiedButton = rootTabButton(for: tab)
        let button = identifiedButton.waitForExistence(timeout: 5)
            ? identifiedButton
            : base.app.tabBars.buttons.element(boundBy: tab.index)
        base.assertVisible(button, timeout: 15, description: tab.description, file: file, line: line)
        button.tap()
        if tab == .search {
            base.assertExists(
                base.app.otherElements[AccessibilityIdentifiers.Search.view],
                timeout: 15,
                description: "Search view",
                file: file,
                line: line
            )
        } else {
            base.assertSelected(button, timeout: 10, description: tab.description, file: file, line: line)
            if tab == .places {
                dismissPlacesLocationPromptIfNeeded(file: file, line: line)
            }
        }
        return self
    }

    private func rootTabButton(for tab: RootTab) -> XCUIElement {
        base.app.buttons.matching(identifier: tab.accessibilityIdentifier).firstMatch
    }

    private func searchTabButtonFallback() -> XCUIElement {
        base.app.tabBars.buttons.element(boundBy: 4)
    }

    private func dismissPlacesLocationPromptIfNeeded(file: StaticString = #filePath, line: UInt = #line) {
        let alert = base.app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 2) else {
            return
        }

        let cancelButton = alert.buttons["Cancel"]
        let dismissButton = cancelButton.exists ? cancelButton : alert.buttons.element(boundBy: 1)
        base.assertVisible(
            dismissButton,
            timeout: 5,
            description: "Places location prompt dismiss button",
            file: file,
            line: line
        )
        dismissButton.tap()
    }
}
