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
}

// MARK: - Root tabs

extension ExploreRobot {
    enum RootTab: CaseIterable {
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

    }
}

// MARK: - Screen state

extension ExploreRobot {
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
    func assertRootTabAccessibilityIdentifiersSurfaced(file: StaticString = #filePath, line: UInt = #line) -> Self {
        for tab in RootTab.allCases {
            base.assertExists(
                base.app.buttons[tab.accessibilityIdentifier],
                timeout: 15,
                description: "\(tab.description) accessibility identifier",
                file: file,
                line: line
            )
        }
        return self
    }
}

// MARK: - Content

extension ExploreRobot {
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
        tapRootTab(.search, file: file, line: line)
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
        let button = rootTabButton(for: tab)
        base.assertVisible(button, timeout: 15, description: tab.description, file: file, line: line)
        base.tapCenter(of: button, file: file, line: line)

        switch tab {
        case .search:
            if !searchView.waitForExistence(timeout: 15) {
                let retryButton = rootTabButton(for: tab)
                base.assertVisible(retryButton, timeout: 5, description: tab.description, file: file, line: line)
                base.tapCenter(of: retryButton, file: file, line: line)
                base.assertExists(
                    searchView,
                    timeout: 15,
                    description: "Search view",
                    file: file,
                    line: line
                )
            }
        case .places:
            base.assertSelected(button, timeout: 10, description: tab.description, file: file, line: line)
            dismissPlacesLocationPromptIfNeeded(file: file, line: line)
        default:
            base.assertSelected(button, timeout: 10, description: tab.description, file: file, line: line)
        }

        return self
    }
}

// MARK: - Private helpers

private extension ExploreRobot {
    func rootTabButton(for tab: RootTab) -> XCUIElement {
        base.app.buttons.matching(identifier: tab.accessibilityIdentifier).firstMatch
    }

    var searchView: XCUIElement {
        base.app.otherElements[AccessibilityIdentifiers.Search.view]
    }

    func dismissPlacesLocationPromptIfNeeded(file: StaticString = #filePath, line: UInt = #line) {
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
