import XCTest
import WMFComponents

/// Represents the Home tab after app launch or onboarding dismissal.
struct HomeRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }
}

// MARK: - Root tabs

extension HomeRobot {
    enum RootTab: CaseIterable {
        case activity
        case home
        case places
        case saved
        case search

        var accessibilityIdentifier: String {
            switch self {
            case .activity:
                return AccessibilityIdentifiers.RootTab.activityButton
            case .home:
                return AccessibilityIdentifiers.RootTab.homeButton
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
            case .home:
                return "Home root tab"
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

extension HomeRobot {
    @discardableResult
    func assertVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        dismissYearInReviewAnnouncementIfPresent()
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Home.view],
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

extension HomeRobot {
    /// The Community segment title per test language, from `home-community-tab-title`. Hebrew has
    /// no translation yet and shows the English title.
    private static let communitySegmentTitles: [String: String] = [
        "en": "Community",
        "de": "Gemeinschaft",
        "he": "Community",
        "vi": "Cộng đồng"
    ]

    /// The Community segment, found by its title. The segment order follows the layout direction,
    /// so an index would pick "For You" in right-to-left languages; the first segment is only a
    /// fallback for a title this table does not know.
    private var communitySegment: XCUIElement {
        let segments = base.app.segmentedControls.buttons
        if let title = Self.communitySegmentTitles[configuration.languageCode] {
            let titledSegment = segments.matching(NSPredicate(format: "label == %@", title)).firstMatch
            if titledSegment.waitForExistence(timeout: 15) {
                return titledSegment
            }
        }
        return segments.element(boundBy: 0)
    }

    @discardableResult
    func openFirstArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        // Article cells live in the Community segment of the Home tab.
        let communitySegment = self.communitySegment
        if communitySegment.waitForExistence(timeout: 15), !communitySegment.isSelected {
            communitySegment.tap()
        }
        let articleCells = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Explore.articleCell)
        let articleCell = base.firstHittableElement(
            matching: articleCells,
            timeout: 60,
            description: "Community feed article cell",
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
    func openSaved(file: StaticString = #filePath, line: UInt = #line) -> SavedRobot {
        tapRootTab(.saved, file: file, line: line)
        return SavedRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
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
        dismissYearInReviewAnnouncementIfPresent()
        let button = rootTabButton(for: tab)
        // A cold launch on CI takes 40+ seconds and the tab bar settles after that.
        base.assertVisible(button, timeout: 30, description: tab.description, file: file, line: line)
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
            tapAgainIfNotSelected(button, file: file, line: line)
            base.assertSelected(button, timeout: 10, description: tab.description, file: file, line: line)
            dismissPlacesLocationPromptIfNeeded(file: file, line: line)
        default:
            tapAgainIfNotSelected(button, file: file, line: line)
            base.assertSelected(button, timeout: 10, description: tab.description, file: file, line: line)
        }

        return self
    }
}

// MARK: - Private helpers

private extension HomeRobot {
    /// On a slow runner the first tap after launch can land while the tab bar still settles, and the tab
    /// never gets selected. Tap once more before the assert fails the test.
    func tapAgainIfNotSelected(_ button: XCUIElement, timeout: TimeInterval = 10, file: StaticString, line: UInt) {
        if !base.isSelected(button, within: timeout) {
            base.tapCenter(of: button, file: file, line: line)
        }
    }
}

private extension HomeRobot {
    func rootTabButton(for tab: RootTab) -> XCUIElement {
        base.app.buttons.matching(identifier: tab.accessibilityIdentifier).firstMatch
    }

    var searchView: XCUIElement {
        base.app.otherElements[AccessibilityIdentifiers.Search.view]
    }

    /// The Year in Review announcement is a sheet that can appear shortly after launch and cover
    /// the tab bar. If it is on screen, close it so the test can continue.
    func dismissYearInReviewAnnouncementIfPresent() {
        let closeButton = base.app.buttons[AccessibilityIdentifiers.YearInReview.closeButton]
        guard closeButton.waitForExistence(timeout: 3), closeButton.isHittable else {
            return
        }
        closeButton.tap()
        _ = closeButton.waitForNonExistence(timeout: 5)
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
