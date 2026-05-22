import XCTest
import WMFComponents

/// Represents an article screen and its top navigation controls.
struct ArticleRobot: ScreenshotCapturingRobot {
    let base: UITestRobot
    private let configuration: UITestConfiguration

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
        let backButton = base.backButton(in: navigationBar, isRightToLeft: configuration.isRightToLeft)
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

    @discardableResult
    func tapLeadImage(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let leadImage = base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Article.leadImage)
            .firstMatch
        base.assertVisible(leadImage, timeout: 15, description: "article lead image", file: file, line: line)
        leadImage.tap()
        return self
    }

    @discardableResult
    func tapNonLeadImage(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.nonLeadImage, maxScrolls: 15, file: file, line: line).tap()
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

    @discardableResult
    func openArticleLinkContextMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let articleLink = visibleArticleElement(matchingLabel: ArticleContentLabel.articleLink, maxScrolls: 3, file: file, line: line)
        articleLink.press(forDuration: 1.2)
        return assertArticleLinkContextMenuVisible(file: file, line: line)
    }

    @discardableResult
    func assertArticleLinkContextMenuVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        for action in ArticleLinkContextMenuAction.visibleInLongPressMenu {
            let item = contextMenuItem(for: action)
            base.assertExists(item, timeout: 5, description: "\(action.title) context menu item", file: file, line: line)
        }

        assertArticleLinkPreviewVisible(file: file, line: line)
        return self
    }

    @discardableResult
    func dismissArticleLinkContextMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let openMenuItem = contextMenuItem(for: .open)
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)).tap()
        base.waitForElementToDisappear(openMenuItem, timeout: 5, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapArticleLink(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.articleLink, maxScrolls: 3, file: file, line: line).tap()
        _ = visibleArticleElement(matchingLabel: ArticleContentLabel.articleLinkDescription, maxScrolls: 2, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapQuickFactsTableItem(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.quickFactsTable, maxScrolls: 3, file: file, line: line).tap()
        visibleArticleElement(matchingLabel: ArticleContentLabel.quickFactsTableItem, maxScrolls: 3, file: file, line: line).tap()
        _ = visibleArticleElement(matchingLabel: ArticleContentLabel.articleLinkDescription, maxScrolls: 2, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapProtectedEditIcon(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.protectedEditIcon, maxScrolls: 2, file: file, line: line).tap()
        return self
    }

    @discardableResult
    func tapUnprotectedEditIcon(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.unprotectedEditIcon, maxScrolls: 2, file: file, line: line).tap()
        return self
    }

    @discardableResult
    func tapAboutThisArticleItem(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.footerItem, maxScrolls: 20, file: file, line: line).tap()
        return self
    }

    @discardableResult
    func tapLicenseLink(file: StaticString = #filePath, line: UInt = #line) -> Self {
        visibleArticleElement(matchingLabel: ArticleContentLabel.licenseLink, maxScrolls: 20, file: file, line: line).tap()
        return self
    }

    @discardableResult
    func rotateAndAssertArticleWorks(file: StaticString = #filePath, line: UInt = #line) -> Self {
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = assertVisible(file: file, line: line)
        _ = assertTopControlsVisible(file: file, line: line)

        XCUIDevice.shared.orientation = .portrait
        _ = assertVisible(file: file, line: line)
        return assertTopControlsVisible(file: file, line: line)
    }

    private func visibleArticleElement(matchingLabel label: String, maxScrolls: Int, file: StaticString, line: UInt) -> XCUIElement {
        visibleArticleElement(matching: NSPredicate(format: "label == %@", label), description: label, maxScrolls: maxScrolls, file: file, line: line)
    }

    private func visibleArticleElement(matching predicate: NSPredicate, description: String, maxScrolls: Int, file: StaticString, line: UInt) -> XCUIElement {
        let element = articleElement(matching: predicate)
        if element.waitForExistence(timeout: 2), element.isHittable {
            return element
        }

        for _ in 0..<maxScrolls {
            if element.exists && element.isHittable {
                return element
            }
            base.app.swipeUp()
        }

        base.assertVisible(element, timeout: 2, description: "article element labeled '\(description)'", file: file, line: line)
        return element
    }

    private func articleElement(matching predicate: NSPredicate) -> XCUIElement {
        return base.app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func contextMenuItem(for action: ArticleLinkContextMenuAction) -> XCUIElement {
        let predicate = NSPredicate(format: "label == %@ OR identifier == %@", action.title, action.title)
        return base.app.buttons.matching(predicate).firstMatch
    }

    private func assertArticleLinkPreviewVisible(file: StaticString, line: UInt) {
        let preview = base.app.otherElements[AccessibilityIdentifiers.Article.linkPreview]
        if preview.waitForExistence(timeout: 2) {
            return
        }

        let previewContentPredicate = NSPredicate(
            format: "label == %@ OR label CONTAINS %@",
            ArticleContentLabel.articleLinkPreviewTitle,
            ArticleContentLabel.articleLinkPreviewDescription
        )
        let previewContent = base.app.descendants(matching: .any).matching(previewContentPredicate).firstMatch

        XCTAssertTrue(
            previewContent.waitForExistence(timeout: 5),
            "Expected article link preview content to exist.",
            file: file,
            line: line
        )
    }
    
    // MARK: - Navigation elements
    
    private var homeButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.homeButton]
    }

    private var searchButton: XCUIElement {
        base.app.buttons[AccessibilityIdentifiers.Article.searchButton]
    }

    private func navigationBar(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let navigationBar = base.app.navigationBars.firstMatch
        base.assertExists(navigationBar, description: "article navigation bar", file: file, line: line)
        return navigationBar
    }
}

fileprivate extension ArticleRobot {
    enum ArticleLinkContextMenuAction: CaseIterable {
        case open
        case openInNewTab
        case openInBackground
        case saveForLater
        case share

        static let visibleInLongPressMenu: [Self] = [
            .open,
            .openInNewTab,
            .openInBackground,
            .share
        ]

        var title: String {
            switch self {
            case .open:
                return "Open"
            case .openInNewTab:
                return "Open in new tab"
            case .openInBackground:
                return "Open in background tab"
            case .saveForLater:
                return "Save for later"
            case .share:
                return "Share\u{2026}"
            }
        }
    }

    private enum ArticleContentLabel {
        static let articleLink = "Article Link Canis"
        static let articleLinkPreviewTitle = "Canis"
        static let articleLinkPreviewDescription = "Genus of mammals"
        static let articleLinkDescription = "Genus of canines"
        static let nonLeadImage = "Article Non-Lead Image"
        static let quickFactsTable = "Article Quick Facts Table"
        static let quickFactsTableItem = "Article Quick Facts Table Link"
        static let footerItem = "Article About This Article Item"
        static let licenseLink = "Article License Link"
        static let protectedEditIcon = "Edit section on protected page"
        static let unprotectedEditIcon = "Edit section"
    }
}
