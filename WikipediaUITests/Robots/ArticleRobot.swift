import Foundation
import XCTest
import WMFComponents

/// Represents an article screen and its top navigation controls.
struct ArticleRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration
    private static let articleElementSearchTimeout: TimeInterval = 30

    init(base: UITestRobot, configuration: UITestConfiguration) {
        self.base = base
        self.configuration = configuration
    }
}

// MARK: - Screen state

extension ArticleRobot {
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
    func assertTabsOverviewVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.Tabs.view],
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func rotateAndAssertArticleWorks(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.rotateToLandscapeLeft()
        _ = assertVisible(file: file, line: line)
        _ = assertTopControlsVisible(file: file, line: line)

        base.rotateToPortrait()
        _ = assertVisible(file: file, line: line)
        return assertTopControlsVisible(file: file, line: line)
    }
}

// MARK: - Navigation

extension ArticleRobot {
    @discardableResult
    func tapBackToExplore(file: StaticString = #filePath, line: UInt = #line) -> ExploreRobot {
        let navigationBar = navigationBar(file: file, line: line)
        base.assertVisible(navigationBar.buttons.firstMatch, timeout: 15, description: "article navigation button", file: file, line: line)
        let backButton = base.backButton(in: navigationBar, isRightToLeft: configuration.isRightToLeft)
        base.assertExists(backButton, timeout: 15, description: "article back button", file: file, line: line)
        XCTAssertFalse(backButton.frame.isEmpty, "Expected article back button to have a tappable frame.", file: file, line: line)
        backButton.tap()
        return ExploreRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapHomeButtonToExplore(file: StaticString = #filePath, line: UInt = #line) -> ExploreRobot {
        let navigationHomeButton = navigationBar(file: file, line: line)
            .buttons
            .matching(identifier: AccessibilityIdentifiers.Article.homeButton)
            .firstMatch
        let button = navigationHomeButton.waitForExistence(timeout: 5)
            ? navigationHomeButton
            : homeButton
        base.assertVisible(button, timeout: 15, description: "article W home button", file: file, line: line)
        button.tap()
        return ExploreRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapSearch(file: StaticString = #filePath, line: UInt = #line) -> SearchRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.searchButton, file: file, line: line)
        return SearchRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }
}

// MARK: - Images

extension ArticleRobot {
    @discardableResult
    func openLeadImageGallery(file: StaticString = #filePath, line: UInt = #line) -> ImageGalleryRobot {
        base.assertExists(leadImage, timeout: 30, description: "article lead image", file: file, line: line)
        leadImage.tap()
        return ImageGalleryRobot(base: base)
            .assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapLeadImage(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(leadImage, timeout: 15, description: "article lead image", file: file, line: line)
        leadImage.tap()
        return self
    }

    @discardableResult
    func tapNonLeadImage(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.nonLeadImage, file: file, line: line)
        return self
    }

    @discardableResult
    func assertImageGalleryVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            base.app.otherElements[AccessibilityIdentifiers.ImageGallery.view],
            timeout: 10,
            description: "image gallery",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func closeImageGallery(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let closeButton = base.app.buttons[AccessibilityIdentifiers.ImageGallery.closeButton]
        base.assertExists(closeButton, timeout: 10, description: "image gallery close button", file: file, line: line)
        closeButton.tap()
        return assertVisible(file: file, line: line)
    }
}

// MARK: - Article content

extension ArticleRobot {
    @discardableResult
    func openArticleLinkContextMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let articleLink = articleElement(.articleLink, file: file, line: line)
        pressArticleElement(articleLink, forDuration: 1.2, file: file, line: line)
        return assertArticleLinkContextMenuVisible(file: file, line: line)
    }

    @discardableResult
    func openQuickFactsArticleLinkContextMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.quickFactsTable, file: file, line: line)
        let articleLink = articleElement(.articleLink, file: file, line: line)
        pressArticleElement(articleLink, forDuration: 1.2, file: file, line: line)
        return assertArticleLinkContextMenuVisible(file: file, line: line)
    }

    @discardableResult
    func assertArticleLinkContextMenuVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        for title in articleControlsFixture.contextMenuActionTitles {
            let item = contextMenuItem(withTitle: title)
            base.assertExists(item, timeout: 5, description: "\(title) context menu item", file: file, line: line)
        }

        assertArticleLinkPreviewVisible(file: file, line: line)
        return self
    }

    @discardableResult
    func dismissArticleLinkContextMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let openMenuItem = contextMenuItem(withTitle: articleControlsFixture.contextMenuActionTitles[0])
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        base.waitForElementToDisappear(openMenuItem, timeout: 5, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapQuickFactsTableItem(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.quickFactsTable, file: file, line: line)
        tapArticleElement(.quickFactsTableItem, file: file, line: line)
        assertArticleElementExists(matchingLabel: articleControlsFixture.linkedArticleDescription, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapProtectedEditIcon(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.protectedEditIcon, file: file, line: line)
        return self
    }

    @discardableResult
    func tapUnprotectedEditIcon(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.unprotectedEditIcon, file: file, line: line)
        return self
    }

    @discardableResult
    func tapAboutThisArticleItem(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.footerItem, file: file, line: line)
        return assertHistoryVisibleAndReturnToArticle(file: file, line: line)
    }

    @discardableResult
    func tapLicenseLink(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.licenseLink, file: file, line: line)
        return self
    }
}

extension ArticleRobot {
    struct ArticleControlsFixture {
        let primaryArticleTitle: String
        let linkedArticleTitle: String
        let linkedArticleDescription: String
        let footerArticleTitle: String
        let contextMenuActionTitles: [String]
    }

    static func articleControlsFixture(languageCode: String) -> ArticleControlsFixture? {
        switch languageCode {
        case "en":
            return ArticleControlsFixture(
                primaryArticleTitle: "Dog",
                linkedArticleTitle: "Canis",
                linkedArticleDescription: "Genus of canines",
                footerArticleTitle: "Canis lepophagus",
                contextMenuActionTitles: [
                    "Open",
                    "Open in new tab",
                    "Open in background tab",
                    "Share…"
                ]
            )
        case "de":
            return ArticleControlsFixture(
                primaryArticleTitle: "Haushund",
                linkedArticleTitle: "Wolfs- und Schakalartige",
                linkedArticleDescription: "Gattung der Familie Hunde (Canidae)",
                footerArticleTitle: "Wolfs- und Schakalartige",
                contextMenuActionTitles: [
                    "Öffnen",
                    "In neuem Tab öffnen",
                    "Im Hintergrund-Tab öffnen",
                    "Teilen ..."
                ]
            )
        case "he":
            return ArticleControlsFixture(
                primaryArticleTitle: "כלב הבית",
                linkedArticleTitle: "כלב (סוג)",
                linkedArticleDescription: "סוג של בעל חיים",
                footerArticleTitle: "כלב (סוג)",
                contextMenuActionTitles: [
                    "פתיחה",
                    "פתיחה בלשונית חדשה",
                    "פתיחה בלשונית ברקע",
                    "שיתוף..."
                ]
            )
        case "vi":
            return ArticleControlsFixture(
                primaryArticleTitle: "Chó",
                linkedArticleTitle: "Chi Chó",
                linkedArticleDescription: "chi động vật có vú, bao gồm chó nhà",
                footerArticleTitle: "Chi Chó",
                contextMenuActionTitles: [
                    "Mở",
                    "Mở trong thẻ mới",
                    "Open in background tab",
                    "Chia sẻ…"
                ]
            )
        default:
            return nil
        }
    }
}

// MARK: - Private helpers

private extension ArticleRobot {
    enum ArticleContentElement: String {
        case articleLink = "Article Link Canis"
        case nonLeadImage = "Article Non-Lead Image"
        case quickFactsTable = "Article Quick Facts Table"
        case quickFactsTableItem = "Article Quick Facts Table Link"
        case footerItem = "Article About This Article Item"
        case licenseLink = "Article License Link"
        case protectedEditIcon = "Edit section on protected page"
        case unprotectedEditIcon = "Edit section"
    }

    var articleControlsFixture: ArticleControlsFixture {
        guard let fixture = Self.articleControlsFixture(languageCode: configuration.languageCode) else {
            preconditionFailure("Article control robot actions require a bundled article-control fixture language.")
        }

        return fixture
    }

    var leadImage: XCUIElement {
        base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Article.leadImage)
            .firstMatch
    }

    var homeButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.homeButton]
    }

    var searchButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.searchButton]
    }

    func navigationBar(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let navigationBar = base.app.navigationBars.firstMatch
        base.assertExists(navigationBar, description: "article navigation bar", file: file, line: line)
        return navigationBar
    }

    func articleElement(_ articleContentElement: ArticleContentElement, file: StaticString, line: UInt) -> XCUIElement {
        articleElement(matchingLabel: articleContentElement.rawValue, file: file, line: line)
    }

    func articleElement(matchingLabel label: String, file: StaticString, line: UInt) -> XCUIElement {
        articleElement(matching: NSPredicate(format: "label == %@", label), description: label, file: file, line: line)
    }

    func articleElement(matching predicate: NSPredicate, description: String, file: StaticString, line: UInt) -> XCUIElement {
        let element = base.app.descendants(matching: .any).matching(predicate).firstMatch
        if element.waitForExistence(timeout: 2), canInteractWithArticleElement(element) {
            return element
        }

        let timeoutDate = Date().addingTimeInterval(Self.articleElementSearchTimeout)
        repeat {
            if canInteractWithArticleElement(element) {
                return element
            }

            scrollArticleTowardElement(element)
        } while Date() < timeoutDate

        XCTAssertTrue(
            canInteractWithArticleElement(element),
            "Expected article element labeled '\(description)' to be on screen within \(Self.articleElementSearchTimeout) seconds.",
            file: file,
            line: line
        )
        return element
    }

    func assertArticleElementExists(matchingLabel label: String, file: StaticString, line: UInt) {
        _ = articleElement(matchingLabel: label, file: file, line: line)
    }

    func tapArticleElement(_ articleContentElement: ArticleContentElement, file: StaticString, line: UInt) {
        tapArticleElement(articleElement(articleContentElement, file: file, line: line), file: file, line: line)
    }

    func tapArticleElement(_ element: XCUIElement, file: StaticString, line: UInt) {
        element.tap()
    }

    func pressArticleElement(_ element: XCUIElement, forDuration duration: TimeInterval, file: StaticString, line: UInt) {
        element.press(forDuration: duration)
    }

    func scrollArticleTowardElement(_ element: XCUIElement) {
        if element.exists, !element.frame.isEmpty, element.frame.midY < tappableArticleFrame.minY {
            base.dragDown(articleScrollTarget)
        } else {
            base.dragUp(articleScrollTarget)
        }
    }

    var articleScrollTarget: XCUIElement {
        let webView = base.app.webViews.firstMatch
        return webView.exists ? webView : base.app.scrollViews.firstMatch
    }

    var tappableArticleFrame: CGRect {
        base.app.frame.insetBy(dx: 0, dy: 130)
    }

    func canInteractWithArticleElement(_ element: XCUIElement) -> Bool {
        guard element.exists, !element.frame.isEmpty else {
            return false
        }

        return tappableArticleFrame.contains(CGPoint(x: element.frame.midX, y: element.frame.midY))
    }

    func contextMenuItem(withTitle title: String) -> XCUIElement {
        let titleWithoutTrailingEllipsis = title.trimmingCharacters(in: CharacterSet(charactersIn: " .…"))
        let predicate: NSPredicate
        if titleWithoutTrailingEllipsis != title, !titleWithoutTrailingEllipsis.isEmpty {
            predicate = NSPredicate(
                format: "label == %@ OR identifier == %@ OR label BEGINSWITH %@ OR identifier BEGINSWITH %@",
                title,
                title,
                titleWithoutTrailingEllipsis,
                titleWithoutTrailingEllipsis
            )
        } else {
            predicate = NSPredicate(format: "label == %@ OR identifier == %@", title, title)
        }
        return base.app.buttons.matching(predicate).firstMatch
    }

    func assertArticleLinkPreviewVisible(file: StaticString, line: UInt) {
        let preview = base.app.otherElements[AccessibilityIdentifiers.Article.linkPreview]
        if preview.waitForExistence(timeout: 2) {
            return
        }

        let previewContentPredicate = NSPredicate(
            format: "label == %@ OR label CONTAINS[c] %@",
            articleControlsFixture.linkedArticleTitle,
            articleControlsFixture.linkedArticleDescription
        )
        let previewContent = base.app.descendants(matching: .any).matching(previewContentPredicate).firstMatch

        XCTAssertTrue(
            previewContent.waitForExistence(timeout: 5),
            "Expected article link preview content to exist.",
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertHistoryVisibleAndReturnToArticle(file: StaticString, line: UInt) -> Self {
        let articleView = base.app.otherElements[AccessibilityIdentifiers.Article.view]
        base.waitForElementToDisappear(articleView, timeout: 15, file: file, line: line)

        let historyNavigationBar = base.app.navigationBars.firstMatch
        base.assertExists(historyNavigationBar, timeout: 15, description: "history navigation bar", file: file, line: line)

        let backButton = base.backButton(in: historyNavigationBar, isRightToLeft: configuration.isRightToLeft)
        base.assertExists(backButton, timeout: 15, description: "history back button", file: file, line: line)
        XCTAssertFalse(backButton.frame.isEmpty, "Expected history back button to have a tappable frame.", file: file, line: line)
        backButton.tap()
        return assertVisible(file: file, line: line)
    }
}
