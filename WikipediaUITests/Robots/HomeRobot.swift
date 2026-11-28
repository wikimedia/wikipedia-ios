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
    /// The segment titles per test language, from `home-community-tab-title` and
    /// `home-for-you-tab-title`. Hebrew has no translation yet and shows the English titles.
    private static let segmentTitles: [HomeSegment: [String: String]] = [
        .community: [
            "en": "Community",
            "de": "Gemeinschaft",
            "he": "Community",
            "vi": "Cộng đồng"
        ],
        .forYou: [
            "en": "For You",
            "de": "Für dich",
            "he": "For You",
            "vi": "Dành cho bạn"
        ]
    ]

    /// A segment, found by its title. The segment order follows the layout direction, so an
    /// index would pick the wrong segment in right-to-left languages; the visual position is only a
    /// fallback for a title this table does not know. Community is the leading segment.
    private func segment(_ segment: HomeSegment) -> XCUIElement {
        let segments = base.app.segmentedControls.buttons
        if let title = Self.segmentTitles[segment]?[configuration.languageCode] {
            let titledSegment = segments.matching(NSPredicate(format: "label == %@", title)).firstMatch
            if titledSegment.waitForExistence(timeout: 15) {
                return titledSegment
            }
        }
        let isLeading = segment == .community
        let index = isLeading != configuration.isRightToLeft ? 0 : 1
        return segments.element(boundBy: index)
    }

    private var communitySegment: XCUIElement {
        segment(.community)
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

// MARK: - Feed segments

/// The two segments of the Home tab.
enum HomeSegment {
    case community
    case forYou
}

extension HomeRobot {
    @discardableResult
    func selectSegment(_ homeSegment: HomeSegment, file: StaticString = #filePath, line: UInt = #line) -> Self {
        dismissYearInReviewAnnouncementIfPresent()
        let element = segment(homeSegment)
        base.assertExists(element, timeout: 30, description: "\(homeSegment) segment", file: file, line: line)
        // A selected segment needs no tap. Over some screens returning to Home it also does not
        // report itself hittable, although it is on screen.
        guard !element.isSelected else {
            return self
        }
        base.assertVisible(element, timeout: 30, description: "\(homeSegment) segment", file: file, line: line)
        element.tap()
        tapAgainIfNotSelected(element, timeout: 5, file: file, line: line)
        base.assertSelected(element, timeout: 10, description: "\(homeSegment) segment", file: file, line: line)
        return self
    }

    @discardableResult
    func assertSegmentSelected(_ homeSegment: HomeSegment, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertSelected(segment(homeSegment), timeout: 15, description: "\(homeSegment) segment", file: file, line: line)
        return self
    }

    /// Opens the For You segment. The feed itself loads after this; `ForYouFeedRobot` waits for it.
    @discardableResult
    func openForYou(file: StaticString = #filePath, line: UInt = #line) -> ForYouFeedRobot {
        selectSegment(.forYou, file: file, line: line)
        return ForYouFeedRobot(base: base, configuration: configuration)
    }

    /// Opens the Community segment with Home phase 2 on: the native Community feed.
    @discardableResult
    func openCommunity(file: StaticString = #filePath, line: UInt = #line) -> CommunityFeedRobot {
        selectSegment(.community, file: file, line: line)
        return CommunityFeedRobot(base: base, configuration: configuration)
    }

    /// With Home phase 2 off, the Community segment hosts the legacy Explore feed.
    @discardableResult
    func assertEmbeddedExploreFeedVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Explore.view).firstMatch,
            timeout: 30,
            description: "embedded Explore feed",
            file: file,
            line: line
        )
        let articleCells = base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Explore.articleCell)
        base.assertExists(articleCells.firstMatch, timeout: 60, description: "Explore feed article cell", file: file, line: line)
        return self
    }

    @discardableResult
    func assertNativeCommunityFeedAbsent(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let feed = base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Community.feed).firstMatch
        XCTAssertFalse(feed.waitForExistence(timeout: 3), "Expected the native Community feed to be absent.", file: file, line: line)
        return self
    }
}

// MARK: - Language picker

extension HomeRobot {
    private var languagePickerButton: XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Home.languagePickerButton).firstMatch
    }

    @discardableResult
    func assertLanguagePickerVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(languagePickerButton, timeout: 15, description: "Home language picker", file: file, line: line)
        return self
    }

    /// The embedded Explore feed manages its languages in its own settings, so Home hides the picker.
    @discardableResult
    func assertLanguagePickerAbsent(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCTAssertFalse(languagePickerButton.waitForExistence(timeout: 3), "Expected the Home language picker to be absent.", file: file, line: line)
        return self
    }

    /// Opens the language menu and checks that it lists the app language and "Manage languages".
    @discardableResult
    func openLanguagePicker(file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertLanguagePickerVisible(file: file, line: line)
        languagePickerButton.tap()
        let languageItem = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Home.languageMenuItem(configuration.languageCode))
            .firstMatch
        base.assertExists(languageItem, timeout: 10, description: "language menu item for '\(configuration.languageCode)'", file: file, line: line)
        return self
    }

    @discardableResult
    func tapManageLanguages(file: StaticString = #filePath, line: UInt = #line) -> PreferredLanguagesRobot {
        let manageItem = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Home.manageLanguagesButton)
            .firstMatch
        base.assertVisible(manageItem, timeout: 10, description: "Manage languages menu item", file: file, line: line)
        manageItem.tap()
        return PreferredLanguagesRobot(base: base).assertVisible(file: file, line: line)
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
