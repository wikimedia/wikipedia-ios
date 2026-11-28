import XCTest
import WMFComponents

/// Represents the native Community feed of the Home tab (Home phase 2): one section per day, with
/// the modules of that day under its date.
struct CommunityFeedRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    enum Module: CaseIterable {
        case featuredArticle
        case topRead
        case inTheNews
        case onThisDay
        case pictureOfTheDay

        /// Matches `WMFCommunityModule.accessibilityID` in the app.
        var accessibilityID: String {
            switch self {
            case .featuredArticle:
                return "featured_article"
            case .topRead:
                return "top_read"
            case .inTheNews:
                return "in_the_news"
            case .onThisDay:
                return "on_this_day"
            case .pictureOfTheDay:
                return "picture_of_the_day"
            }
        }
    }

    enum ModuleMenuItem {
        case hideCard
        case hideModule
        case customize

        var accessibilityIdentifier: String {
            switch self {
            case .hideCard:
                return AccessibilityIdentifiers.Community.menuHideCardItem
            case .hideModule:
                return AccessibilityIdentifiers.Community.menuHideModuleItem
            case .customize:
                return AccessibilityIdentifiers.Community.menuCustomizeItem
            }
        }
    }
}

// MARK: - Navigation

extension CommunityFeedRobot {
    var home: HomeRobot {
        HomeRobot(base: base, configuration: configuration)
    }
}

// MARK: - Screen state

extension CommunityFeedRobot {
    /// Waits for the feed and its first date header. The feed loads after the segment appears.
    @discardableResult
    func assertFeedVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(feed, timeout: 30, description: "Community feed", file: file, line: line)
        base.assertExists(dateHeaders.firstMatch, timeout: 30, description: "Community date header", file: file, line: line)
        return self
    }

    /// The first section is today. Its header ends with today's date, in the format of the feed
    /// language, so the check looks for today's day of the month and year.
    @discardableResult
    func assertTodayHeaderVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let header = dateHeaders.firstMatch
        base.assertExists(header, timeout: 30, description: "Community date header", file: file, line: line)
        let today = Calendar(identifier: .gregorian).dateComponents([.day, .year], from: Date())
        let label = header.label
        XCTAssertTrue(
            label.contains(String(today.day ?? 0)) && label.contains(String(today.year ?? 0)),
            "Expected the first Community date header to show today, but it shows '\(label)'.",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertDateHeaderCount(atLeast count: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let predicate = NSPredicate { _, _ in dateHeaders.count >= count }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 30)
        XCTAssertEqual(result, .completed, "Expected at least \(count) Community date headers, found \(dateHeaders.count).", file: file, line: line)
        return self
    }

    /// Scrolls down until the module's title is on screen.
    @discardableResult
    func assertModuleVisible(_ module: Module, file: StaticString = #filePath, line: UInt = #line) -> Self {
        scrollIntoView(moduleTitle(module), description: "\(module) module title", file: file, line: line)
        return self
    }

    /// The whole feed is checked from the top, so a module that is hidden cannot be below the fold.
    @discardableResult
    func assertModuleAbsent(_ module: Module, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(moduleTitle(module), timeout: 10, file: file, line: line)
        scrollToTop()
        for _ in 0..<24 {
            XCTAssertFalse(moduleTitle(module).exists, "Expected the \(module) module to be absent.", file: file, line: line)
            if isInView(seePastContentButton) {
                break
            }
            dragFeedUp()
        }
        scrollToTop()
        return self
    }

    @discardableResult
    func assertTopReadRowsVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        scrollIntoView(topReadRows.firstMatch, description: "Top read row", file: file, line: line)
        return self
    }

    /// The In the news carousel is a paged view. Its page indicator tells which story is on screen.
    @discardableResult
    func assertNewsStoryPage(_ page: Int, of total: Int, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let indicator = newsPageIndicator
        base.assertExists(indicator, timeout: 10, description: "In the news page indicator", file: file, line: line)
        let pageText = String(page)
        let totalText = String(total)
        let predicate = NSPredicate { _, _ in
            let value = indicator.value as? String ?? ""
            return value.contains(pageText) && value.contains(totalText)
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 10)
        XCTAssertEqual(result, .completed, "Expected In the news to show story \(page) of \(total), but it shows '\(indicator.value as? String ?? "")'.", file: file, line: line)
        return self
    }

    @discardableResult
    func assertSeePastContentVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        scrollIntoView(seePastContentButton, description: "See past community content button", file: file, line: line)
        return self
    }

    @discardableResult
    func assertErrorVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(errorRetryButton, timeout: 30, description: "Community error retry button", file: file, line: line)
        return self
    }

    @discardableResult
    func assertEmptyStateVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(emptyStateCustomizeButton, timeout: 15, description: "Community empty state button", file: file, line: line)
        return self
    }
}

// MARK: - Actions

extension CommunityFeedRobot {
    @discardableResult
    func openFeaturedArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let card = element(AccessibilityIdentifiers.Community.featuredArticle)
        scrollIntoView(card, description: "featured article card", file: file, line: line)
        card.tap()
        return ArticleRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    /// "Save for later" under the featured article. A second tap unsaves.
    @discardableResult
    func tapSaveForLater(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let button = element(AccessibilityIdentifiers.Community.saveForLaterButton)
        scrollIntoView(button, description: "Save for later button", file: file, line: line)
        let labelBefore = button.label
        button.tap()
        // The label turns into "Saved for later" and back, in the feed language.
        let predicate = NSPredicate { _, _ in button.label != labelBefore }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 10)
        XCTAssertEqual(result, .completed, "Expected the Save for later button to change its label after the tap.", file: file, line: line)
        return self
    }

    @discardableResult
    func openTopReadRow(titled title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let row = topReadRows.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        scrollIntoView(row, description: "Top read row '\(title)'", file: file, line: line)
        row.tap()
        return ArticleRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapMoreTopRead(file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        tapScrolledIntoView(AccessibilityIdentifiers.Community.moreTopReadButton, description: "More top read", file: file, line: line)
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.topReadList, file: file, line: line)
    }

    @discardableResult
    func swipeToNextNewsStory(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let story = newsStories.firstMatch
        scrollIntoView(story, description: "In the news story", file: file, line: line)
        if configuration.isRightToLeft {
            story.swipeRight()
        } else {
            story.swipeLeft()
        }
        return self
    }

    @discardableResult
    func openNewsStory(file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        let story = base.firstHittableElement(matching: newsStories, timeout: 10, description: "In the news story", file: file, line: line)
        story.tap()
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.news, file: file, line: line)
    }

    @discardableResult
    func openOnThisDayEvent(file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        tapScrolledIntoView(AccessibilityIdentifiers.Community.onThisDayEvent, description: "On this day event", file: file, line: line)
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.onThisDay, file: file, line: line)
    }

    @discardableResult
    func tapMoreOnThisDay(file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        tapScrolledIntoView(AccessibilityIdentifiers.Community.moreOnThisDayButton, description: "More on this day", file: file, line: line)
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.onThisDay, file: file, line: line)
    }

    @discardableResult
    func openPictureOfTheDay(file: StaticString = #filePath, line: UInt = #line) -> ImageGalleryRobot {
        tapScrolledIntoView(AccessibilityIdentifiers.Community.pictureOfTheDay, description: "Picture of the day", file: file, line: line)
        return ImageGalleryRobot(base: base).assertVisible(file: file, line: line)
    }

    /// Loads the day before the oldest day on screen.
    @discardableResult
    func tapSeePastContent(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapScrolledIntoView(AccessibilityIdentifiers.Community.seePastContentButton, description: "See past community content", file: file, line: line)
        return self
    }

    @discardableResult
    func tapModuleMenuItem(_ item: ModuleMenuItem, in module: Module, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let menuButton = element(AccessibilityIdentifiers.Community.moduleMenuButton(module.accessibilityID))
        scrollIntoView(menuButton, description: "\(module) module menu button", file: file, line: line)
        menuButton.tap()
        let menuItem = element(item.accessibilityIdentifier)
        base.assertVisible(menuItem, timeout: 10, description: "\(module) module menu item \(item)", file: file, line: line)
        menuItem.tap()
        base.waitForElementToDisappear(menuItem, timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func tapCustomizeCommunityFeed(in module: Module, file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        tapModuleMenuItem(.customize, in: module, file: file, line: line)
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.communityFeedSettings, file: file, line: line)
    }

    @discardableResult
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertErrorVisible(file: file, line: line)
        errorRetryButton.tap()
        return self
    }

    /// The empty state's "Manage modules" button opens the Home feed settings.
    @discardableResult
    func tapEmptyStateCustomize(file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        assertEmptyStateVisible(file: file, line: line)
        emptyStateCustomizeButton.tap()
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.homeFeedSettings, file: file, line: line)
    }
}

// MARK: - Private helpers

private extension CommunityFeedRobot {
    var feed: XCUIElement {
        element(AccessibilityIdentifiers.Community.feed)
    }

    var dateHeaders: XCUIElementQuery {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Community.dateHeader)
    }

    var topReadRows: XCUIElementQuery {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Community.topReadRow)
    }

    var newsStories: XCUIElementQuery {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.Community.newsStory)
    }

    var newsPageIndicator: XCUIElement {
        base.app.pageIndicators.firstMatch
    }

    var seePastContentButton: XCUIElement {
        element(AccessibilityIdentifiers.Community.seePastContentButton)
    }

    var errorRetryButton: XCUIElement {
        base.app.buttons.matching(identifier: AccessibilityIdentifiers.Community.errorRetryButton).firstMatch
    }

    var emptyStateCustomizeButton: XCUIElement {
        base.app.buttons.matching(identifier: AccessibilityIdentifiers.Community.emptyStateCustomizeButton).firstMatch
    }

    func moduleTitle(_ module: Module) -> XCUIElement {
        element(AccessibilityIdentifiers.Community.module(module.accessibilityID))
    }

    func element(_ identifier: String) -> XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The header floats over the top of the feed and the tab bar over its bottom, so an element
    /// counts as in view when its center is between them. SwiftUI reports elements of a scroll view
    /// as hittable also when they are off screen, so only the frame decides.
    func isInView(_ element: XCUIElement) -> Bool {
        guard element.exists, !element.frame.isEmpty else { return false }
        let headerBottom = base.app.segmentedControls.firstMatch.frame.maxY
        let tabBarTop = base.app.tabBars.firstMatch.frame.minY
        let midY = element.frame.midY
        return midY > headerBottom + 8 && midY < tabBarTop - 8
    }

    /// Starts at the top of the feed and drags it up in short steps, so a lazily built element
    /// above the screen is never missed and a fling never carries a small target past the screen.
    func scrollIntoView(_ element: XCUIElement, description: String, file: StaticString, line: UInt) {
        base.assertExists(feed, timeout: 30, description: "Community feed", file: file, line: line)
        _ = element.waitForExistence(timeout: 3)
        guard !isInView(element) else { return }
        scrollToTop()
        for _ in 0..<24 where !isInView(element) {
            dragFeedUp()
        }
        XCTAssertTrue(isInView(element), "Expected \(description) to scroll into view.", file: file, line: line)
    }

    /// Drags the feed up by about a third of the screen. The hold at the end stops the scroll
    /// from coasting on. An In the news story scrolls its own text, so a drag that starts on a
    /// story moves the text and not the feed: the drag starts at a height with no story.
    func dragFeedUp() {
        let height = base.app.windows.firstMatch.frame.height
        let storyFrames = newsStories.allElementsBoundByIndex.filter(\.exists).map(\.frame)
        let startY = [0.7, 0.8, 0.6, 0.5].first { fraction in
            let y = height * fraction
            return !storyFrames.contains { $0.minY - 8 <= y && y <= $0.maxY + 8 }
        } ?? 0.7
        let start = base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY - 0.3))
        start.press(forDuration: 0.01, thenDragTo: end, withVelocity: .default, thenHoldForDuration: 0.3)
    }

    func tapScrolledIntoView(_ identifier: String, description: String, file: StaticString, line: UInt) {
        let target = element(identifier)
        scrollIntoView(target, description: description, file: file, line: line)
        target.tap()
    }

    /// A tap on the selected Home tab scrolls the selected feed to the top.
    func scrollToTop() {
        let homeTab = base.app.buttons.matching(identifier: AccessibilityIdentifiers.RootTab.homeButton).firstMatch
        guard homeTab.exists else { return }
        homeTab.tap()
        _ = dateHeaders.firstMatch.waitForExistence(timeout: 3)
        // The scroll is animated.
        let predicate = NSPredicate { _, _ in isInView(dateHeaders.firstMatch) }
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 3)
    }
}
