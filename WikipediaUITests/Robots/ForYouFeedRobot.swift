import XCTest
import WMFComponents

/// Represents the For You segment of the Home tab: a vertical stack of modules, each a horizontal
/// carousel of full-screen article cards, then the end of feed card.
struct ForYouFeedRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }

    /// The items of a card's "More options" menu.
    enum CardMenuItem {
        case save
        case unsave
        case share
        case hideCard
        case hideModule
        case customizeInterests

        var accessibilityIdentifier: String {
            switch self {
            case .save:
                return AccessibilityIdentifiers.ForYou.menuSaveItem
            case .unsave:
                return AccessibilityIdentifiers.ForYou.menuUnsaveItem
            case .share:
                return AccessibilityIdentifiers.ForYou.menuShareItem
            case .hideCard:
                return AccessibilityIdentifiers.ForYou.menuHideCardItem
            case .hideModule:
                return AccessibilityIdentifiers.ForYou.menuHideModuleItem
            case .customizeInterests:
                return AccessibilityIdentifiers.ForYou.menuCustomizeInterestsItem
            }
        }
    }
}

// MARK: - Navigation

extension ForYouFeedRobot {
    var home: HomeRobot {
        HomeRobot(base: base, configuration: configuration)
    }
}

// MARK: - Screen state

extension ForYouFeedRobot {
    /// Waits for the first card. The feed loads from the network after the segment appears.
    @discardableResult
    func assertFeedVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(feed, timeout: 30, description: "For You feed", file: file, line: line)
        base.assertExists(cards.firstMatch, timeout: 30, description: "For You card", file: file, line: line)
        return self
    }

    @discardableResult
    func assertCardVisible(titled title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(card(titled: title), timeout: 30, description: "For You card '\(title)'", file: file, line: line)
        return self
    }

    @discardableResult
    func assertCardAbsent(titled title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.waitForElementToDisappear(card(titled: title), timeout: 10, file: file, line: line)
        return self
    }

    /// The menu of a saved card offers "Unsave". The check closes the menu again.
    @discardableResult
    func assertCardSaved(titled title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertMenuOffers(.unsave, insteadOf: .save, forCardTitled: title, file: file, line: line)
    }

    @discardableResult
    func assertCardNotSaved(titled title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertMenuOffers(.save, insteadOf: .unsave, forCardTitled: title, file: file, line: line)
    }

    @discardableResult
    func assertShareSheetVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(shareSheet, timeout: 15, description: "share sheet", file: file, line: line)
        return self
    }

    @discardableResult
    func dismissShareSheet(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let closeButton = shareSheet.buttons.matching(NSPredicate(format: "identifier == %@ OR identifier == %@", "Close", "header.closeButton")).firstMatch
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        } else {
            base.dragDown(shareSheet)
        }
        base.waitForElementToDisappear(shareSheet, timeout: 10, file: file, line: line)
        return self
    }

    /// Every module is hidden: the segment shows the empty state and its "Manage modules" button.
    @discardableResult
    func assertEmptyStateVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(emptyStateCustomizeButton, timeout: 15, description: "For You empty state button", file: file, line: line)
        return self
    }

    @discardableResult
    func assertErrorVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(errorRetryButton, timeout: 30, description: "For You error retry button", file: file, line: line)
        return self
    }

    @discardableResult
    func assertEndOfFeedVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(endOfFeedCard, timeout: 15, description: "For You end of feed card", file: file, line: line)
        return self
    }
}

// MARK: - Actions

extension ForYouFeedRobot {
    @discardableResult
    func openCard(titled title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        let card = card(titled: title)
        base.assertVisible(card, timeout: 30, description: "For You card '\(title)'", file: file, line: line)
        // The top third of the card is its image or its extract. The menu and the header label sit lower.
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        return ArticleRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapMenuItem(_ item: CardMenuItem, forCardTitled title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        openMenu(forCardTitled: title, file: file, line: line)
        let menuItem = self.menuItem(item)
        base.assertVisible(menuItem, timeout: 10, description: "For You card menu item \(item)", file: file, line: line)
        menuItem.tap()
        base.waitForElementToDisappear(menuItem, timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func tapCustomizeInterests(forCardTitled title: String, file: StaticString = #filePath, line: UInt = #line) -> InterestsRobot {
        tapMenuItem(.customizeInterests, forCardTitled: title, file: file, line: line)
        return InterestsRobot(base: base).assertVisible(file: file, line: line)
    }

    /// The empty state's "Manage modules" button opens the Home feed settings.
    @discardableResult
    func tapEmptyStateCustomize(file: StaticString = #filePath, line: UInt = #line) -> FeedDetailRobot {
        assertEmptyStateVisible(file: file, line: line)
        emptyStateCustomizeButton.tap()
        return FeedDetailRobot(base: base, configuration: configuration).assertVisible(.homeFeedSettings, file: file, line: line)
    }

    @discardableResult
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) -> Self {
        assertErrorVisible(file: file, line: line)
        errorRetryButton.tap()
        return self
    }

    /// Swipes up one module at a time until the end of feed card fills the screen.
    @discardableResult
    func scrollToEndOfFeed(file: StaticString = #filePath, line: UInt = #line) -> Self {
        for _ in 0..<6 where !(endOfFeedCard.exists && endOfFeedCard.isHittable) {
            base.dragUp(feed)
            _ = endOfFeedCard.waitForExistence(timeout: 2)
        }
        return assertEndOfFeedVisible(file: file, line: line)
    }

    /// The end of feed card's Community link switches the Home tab to the Community segment.
    @discardableResult
    func tapEndOfFeedCommunity(file: StaticString = #filePath, line: UInt = #line) -> HomeRobot {
        base.assertVisible(endOfFeedCommunityButton, timeout: 15, description: "end of feed Community link", file: file, line: line)
        endOfFeedCommunityButton.tap()
        return HomeRobot(base: base, configuration: configuration)
    }
}

// MARK: - Private helpers

private extension ForYouFeedRobot {
    var feed: XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.ForYou.feed).firstMatch
    }

    var cards: XCUIElementQuery {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.ForYou.card)
    }

    /// A card's label starts with its header label and ends with the article title.
    func card(titled title: String) -> XCUIElement {
        cards.matching(NSPredicate(format: "label ENDSWITH %@", title)).firstMatch
    }

    func menuItem(_ item: CardMenuItem) -> XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: item.accessibilityIdentifier).firstMatch
    }

    var shareSheet: XCUIElement {
        base.app.otherElements.matching(identifier: "ActivityListView").firstMatch
    }

    var emptyStateCustomizeButton: XCUIElement {
        base.app.buttons.matching(identifier: AccessibilityIdentifiers.ForYou.emptyStateCustomizeButton).firstMatch
    }

    var errorRetryButton: XCUIElement {
        base.app.buttons.matching(identifier: AccessibilityIdentifiers.ForYou.errorRetryButton).firstMatch
    }

    var endOfFeedCard: XCUIElement {
        base.app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.ForYou.endOfFeedCard).firstMatch
    }

    var endOfFeedCommunityButton: XCUIElement {
        base.app.buttons.matching(identifier: AccessibilityIdentifiers.ForYou.endOfFeedCommunityButton).firstMatch
    }

    func openMenu(forCardTitled title: String, file: StaticString, line: UInt) {
        let card = card(titled: title)
        base.assertVisible(card, timeout: 30, description: "For You card '\(title)'", file: file, line: line)
        let menuButton = card.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.ForYou.cardMenuButton).firstMatch
        base.assertVisible(menuButton, timeout: 10, description: "menu button of For You card '\(title)'", file: file, line: line)
        menuButton.tap()
    }

    /// Opens the card menu, checks which save item it offers, and closes the menu without a choice.
    func assertMenuOffers(_ expected: CardMenuItem, insteadOf unexpected: CardMenuItem, forCardTitled title: String, file: StaticString, line: UInt) -> Self {
        openMenu(forCardTitled: title, file: file, line: line)
        let expectedItem = menuItem(expected)
        base.assertVisible(expectedItem, timeout: 10, description: "For You card menu item \(expected)", file: file, line: line)
        XCTAssertFalse(menuItem(unexpected).exists, "Expected the For You card menu not to offer \(unexpected).", file: file, line: line)
        // A tap outside the menu closes it. The top of the card, under the header, has no control.
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        base.waitForElementToDisappear(expectedItem, timeout: 10, file: file, line: line)
        return self
    }
}
