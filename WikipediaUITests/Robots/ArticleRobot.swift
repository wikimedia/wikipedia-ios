import Foundation
import UIKit
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
            timeout: 30,
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
    func assertLoadedArticle(named title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let titlePredicate = NSPredicate(format: "label == %@ OR value == %@", title, title)
        let titleElement = base.app.descendants(matching: .any)
            .matching(titlePredicate)
            .firstMatch
        base.assertExists(
            titleElement,
            timeout: Self.articleElementSearchTimeout,
            description: "article title '\(title)'",
            file: file,
            line: line
        )
        return assertTopControlsVisible(file: file, line: line)
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
    func assertTableOfContentsVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertExists(
            tableOfContentsView,
            timeout: 15,
            description: "article table of contents",
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
        return tapArticleNavigationButtonReturningToExplore(
            backButton,
            description: "article back button",
            file: file,
            line: line
        )
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
        return tapArticleNavigationButtonReturningToExplore(
            button,
            description: "article W home button",
            file: file,
            line: line
        )
    }

    @discardableResult
    func tapSearch(file: StaticString = #filePath, line: UInt = #line) -> SearchRobot {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.searchButton, file: file, line: line)
        return SearchRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    @discardableResult
    func openTableOfContents(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.tableOfContentsButton, file: file, line: line)
        return assertTableOfContentsVisible(file: file, line: line)
    }

    @discardableResult
    func tapBackToArticle(named title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        let navigationBar = navigationBar(file: file, line: line)
        let backButton = base.backButton(in: navigationBar, isRightToLeft: configuration.isRightToLeft)
        base.assertVisible(backButton, timeout: 15, description: "article back button", file: file, line: line)
        tapCenter(of: backButton)
        return assertLoadedArticle(named: title, file: file, line: line)
    }
}

// MARK: - Bottom article controls

extension ArticleRobot {
    @discardableResult
    func switchArticleLanguage(
        to languageCode: String,
        expectedArticleTitle: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.languagesButton, file: file, line: line)
        base.assertExists(
            languagePickerView,
            timeout: 15,
            description: "article language picker",
            file: file,
            line: line
        )

        tapLanguageCell(languageCode, filterTerm: languageSearchTerm(for: languageCode), file: file, line: line)

        return assertLoadedArticle(named: expectedArticleTitle, file: file, line: line)
    }

    @discardableResult
    func tapSaveAndAssertStateChanges(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let saveButton = element(withIdentifier: AccessibilityIdentifiers.Article.saveButton)
        base.assertVisible(saveButton, timeout: 15, description: "article save button", file: file, line: line)
        let initialLabel = saveButton.label
        saveButton.tap()

        let predicate = NSPredicate { _, _ in
            saveButton.exists && saveButton.label != initialLabel
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed,
            "Expected the article save button state to change after tapping it.",
            file: file,
            line: line
        )

        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func findInArticle(searchTerm: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.findInPageButton, file: file, line: line)
        base.assertExists(findInPageView, timeout: 10, description: "find in article bar", file: file, line: line)

        let textField = element(withIdentifier: AccessibilityIdentifiers.Article.findInPageTextField)
        base.assertVisible(textField, timeout: 10, description: "find in article text field", file: file, line: line)
        textField.tap()
        textField.typeText(searchTerm)

        let matchLabel = element(withIdentifier: AccessibilityIdentifiers.Article.findInPageMatchLabel)
        let predicate = NSPredicate { object, _ in
            guard let matchLabel = object as? XCUIElement else {
                return false
            }

            return matchLabel.label.range(of: "[1-9]", options: .regularExpression) != nil
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: matchLabel)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 15),
            .completed,
            "Expected find in article to report at least one match for '\(searchTerm)'.",
            file: file,
            line: line
        )

        base.assertVisible(
            element(withIdentifier: AccessibilityIdentifiers.Article.findInPageNextButton),
            timeout: 10,
            description: "find in article next button",
            file: file,
            line: line
        )
        base.assertVisible(
            element(withIdentifier: AccessibilityIdentifiers.Article.findInPagePreviousButton),
            timeout: 10,
            description: "find in article previous button",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func closeFindInArticle(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let closeButton = element(withIdentifier: AccessibilityIdentifiers.Article.findInPageCloseButton)
        base.assertVisible(closeButton, timeout: 10, description: "find in article close button", file: file, line: line)
        closeButton.tap()
        base.waitForElementToDisappear(findInPageView, timeout: 10, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func openReadingThemeControls(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.themeButton, file: file, line: line)
        base.assertExists(
            readingThemesView,
            timeout: 10,
            description: "reading theme controls",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func adjustReadingThemeControls(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapControl(withIdentifier: AccessibilityIdentifiers.Article.readingThemesTextSizeSlider, xOffset: 0.8, file: file, line: line)
        tapControl(withIdentifier: AccessibilityIdentifiers.Article.readingThemesBrightnessSlider, xOffset: 0.35, file: file, line: line)
        tapControl(withIdentifier: AccessibilityIdentifiers.Article.readingThemesSepiaButton, file: file, line: line)
        tapControl(withIdentifier: AccessibilityIdentifiers.Article.readingThemesDarkButton, file: file, line: line)
        tapControl(withIdentifier: AccessibilityIdentifiers.Article.readingThemesLightButton, file: file, line: line)
        return self
    }

    @discardableResult
    func dismissReadingThemeControls(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let themesView = readingThemesView
        base.assertExists(themesView, timeout: 10, description: "reading theme controls", file: file, line: line)
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)).tap()
        waitForElementToStopBeingVisible(themesView, timeout: 10, file: file, line: line)
        return assertVisible(file: file, line: line)
    }
}

// MARK: - Table of contents

extension ArticleRobot {
    @discardableResult
    func dismissTableOfContentsByTappingOutside(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let tocView = tableOfContentsView
        base.assertExists(tocView, timeout: 10, description: "article table of contents", file: file, line: line)
        let offset = configuration.isRightToLeft ? CGVector(dx: 0.05, dy: 0.5) : CGVector(dx: 0.95, dy: 0.5)
        base.app.coordinate(withNormalizedOffset: offset).tap()
        base.waitForElementToDisappear(tocView, timeout: 10, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapTableOfContentsSection(
        anchor: String,
        expectedHeading: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let tocView = tableOfContentsView
        let sectionCell = scrollToTableOfContentsCell(anchor: anchor, timeout: 20, file: file, line: line)
        tapCenter(of: sectionCell)
        _ = waitForArticleViewToDisappear(tocView, timeout: 10)
        assertArticleElementExists(matchingLabel: expectedHeading, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func rotateAndAssertTableOfContentsWorks(
        anchor: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        base.rotateToLandscapeLeft()
        _ = assertVisible(file: file, line: line)
        _ = openTableOfContents(file: file, line: line)
        let tocView = tableOfContentsView
        let sectionCell = scrollToTableOfContentsCell(anchor: anchor, timeout: 20, file: file, line: line)
        tapCenter(of: sectionCell)
        waitForElementToStopBeingVisible(tocView, timeout: 10, file: file, line: line)
        _ = assertVisible(file: file, line: line)
        base.rotateToPortrait()
        return assertVisible(file: file, line: line)
    }
}

// MARK: - Images

extension ArticleRobot {
    @discardableResult
    func openLeadImageGallery(file: StaticString = #filePath, line: UInt = #line) -> ImageGalleryRobot {
        base.assertVisible(leadImage, timeout: 60, description: "article lead image", file: file, line: line)
        base.tapCenter(of: leadImage, file: file, line: line)
        return ImageGalleryRobot(base: base)
            .assertVisible(timeout: 60, file: file, line: line)
    }

    @discardableResult
    func tapLeadImage(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.assertVisible(leadImage, timeout: 15, description: "article lead image", file: file, line: line)
        base.tapCenter(of: leadImage, file: file, line: line)
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
        return self
    }

    @discardableResult
    func assertLinkedArticleVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
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
        return self
    }

    @discardableResult
    func assertHistoryVisible(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let articleView = base.app.otherElements[AccessibilityIdentifiers.Article.view]
        base.waitForElementToDisappear(articleView, timeout: 15, file: file, line: line)

        let historyNavigationBar = base.app.navigationBars.firstMatch
        base.assertExists(historyNavigationBar, timeout: 15, description: "history navigation bar", file: file, line: line)
        return self
    }

    @discardableResult
    func tapBackToArticleFromHistory(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let historyNavigationBar = base.app.navigationBars.firstMatch
        base.assertExists(historyNavigationBar, timeout: 15, description: "history navigation bar", file: file, line: line)

        let backButton = base.backButton(in: historyNavigationBar, isRightToLeft: configuration.isRightToLeft)
        base.assertExists(backButton, timeout: 15, description: "history back button", file: file, line: line)
        XCTAssertFalse(backButton.frame.isEmpty, "Expected history back button to have a tappable frame.", file: file, line: line)
        backButton.tap()
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapLicenseLink(file: StaticString = #filePath, line: UInt = #line) -> Self {
        tapArticleElement(.licenseLink, file: file, line: line)
        return self
    }

    @discardableResult
    func tapArticleLinkAndAssertLoaded(file: StaticString = #filePath, line: UInt = #line) -> Self {
        if articleControlsFixture.linkedArticleIsInQuickFacts {
            tapArticleElement(.quickFactsTable, file: file, line: line)
        }

        tapArticleElement(.articleLink, file: file, line: line)
        return assertLoadedArticle(named: articleControlsFixture.linkedArticleTitle, file: file, line: line)
    }
}

// MARK: - Overflow menu

extension ArticleRobot {
    @discardableResult
    func openOverflowMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        base.tapButton(withIdentifier: AccessibilityIdentifiers.Article.moreButton, file: file, line: line)
        return self
    }

    @discardableResult
    func assertOverflowMenuItemsVisible(_ titles: [String], file: StaticString = #filePath, line: UInt = #line) -> Self {
        for title in titles {
            let item = contextMenuItem(withTitle: title)
            base.assertExists(item, timeout: 5, description: "\(title) overflow menu item", file: file, line: line)
            XCTAssertTrue(item.isEnabled, "Expected \(title) overflow menu item to be enabled.", file: file, line: line)
        }
        return self
    }

    @discardableResult
    func dismissOverflowMenu(file: StaticString = #filePath, line: UInt = #line) -> Self {
        let shareItem = contextMenuItem(withTitle: articleControlsFixture.overflowShareTitle)
        base.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        base.waitForElementToDisappear(shareItem, timeout: 5, file: file, line: line)
        return assertVisible(file: file, line: line)
    }

    @discardableResult
    func tapOverflowMenuItemAndAssertMenuDismisses(
        title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        openOverflowMenu(file: file, line: line)
        let item = contextMenuItem(withTitle: title)
        base.assertExists(item, timeout: 10, description: "\(title) overflow menu item", file: file, line: line)
        item.tap()
        waitForElementToStopBeingVisible(item, timeout: 10, file: file, line: line)
        return self
    }

    @discardableResult
    func tapOverflowPreviousArticle(named title: String, file: StaticString = #filePath, line: UInt = #line) -> Self {
        openOverflowMenu(file: file, line: line)
        let item = contextMenuItem(withTitle: title)
        base.assertExists(item, timeout: 10, description: "\(title) previous article overflow menu item", file: file, line: line)
        item.tap()
        return assertLoadedArticle(named: title, file: file, line: line)
    }

    @discardableResult
    func tapOverflowRevisionHistoryAndReturn(file: StaticString = #filePath, line: UInt = #line) -> Self {
        openOverflowMenu(file: file, line: line)
        let item = contextMenuItem(withTitle: articleControlsFixture.overflowRevisionHistoryTitle)
        base.assertExists(item, timeout: 10, description: "revision history overflow menu item", file: file, line: line)
        item.tap()
        return assertHistoryVisible(file: file, line: line)
            .tapBackToArticleFromHistory(file: file, line: line)
    }

}

extension ArticleRobot {
    struct ArticleControlsTableOfContentsSection {
        let anchor: String
        let heading: String
    }

    struct ArticleControlsFixture {
        let primaryArticleTitle: String
        let linkedArticleTitle: String
        let linkedArticleDescription: String
        let linkedArticleIsInQuickFacts: Bool
        let footerArticleTitle: String
        let languageSwitchTargetCode: String
        let languageSwitchTargetTitle: String
        let findSearchTerm: String
        let tableOfContentsSections: [ArticleControlsTableOfContentsSection]
        let rotatedTableOfContentsAnchor: String
        let overflowEditSourceTitle: String
        let overflowRevisionHistoryTitle: String
        let overflowTalkPageTitle: String
        let overflowWatchTitle: String
        let overflowShareTitle: String
        let contextMenuActionTitles: [String]

        var overflowMenuTitles: [String] {
            [
                overflowEditSourceTitle,
                overflowRevisionHistoryTitle,
                overflowTalkPageTitle,
                overflowWatchTitle,
                overflowShareTitle
            ]
        }
    }

    static func articleControlsFixture(languageCode: String) -> ArticleControlsFixture? {
        switch languageCode {
        case "en":
            return ArticleControlsFixture(
                primaryArticleTitle: "Dog",
                linkedArticleTitle: "Canis",
                linkedArticleDescription: "Genus of canines",
                linkedArticleIsInQuickFacts: false,
                footerArticleTitle: "Canis lepophagus",
                languageSwitchTargetCode: "de",
                languageSwitchTargetTitle: "Haushund",
                findSearchTerm: "Canis",
                tableOfContentsSections: [
                    ArticleControlsTableOfContentsSection(anchor: "Taxonomy", heading: "Taxonomy"),
                    ArticleControlsTableOfContentsSection(anchor: "Origin", heading: "Origin")
                ],
                rotatedTableOfContentsAnchor: "Taxonomy",
                overflowEditSourceTitle: "Edit source",
                overflowRevisionHistoryTitle: "Article revision history",
                overflowTalkPageTitle: "Article talk page",
                overflowWatchTitle: "Watch",
                overflowShareTitle: "Share",
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
                linkedArticleIsInQuickFacts: true,
                footerArticleTitle: "Schakal",
                languageSwitchTargetCode: "en",
                languageSwitchTargetTitle: "Dog",
                findSearchTerm: "Canis",
                tableOfContentsSections: [
                    ArticleControlsTableOfContentsSection(anchor: "Etymologie", heading: "Etymologie"),
                    ArticleControlsTableOfContentsSection(anchor: "Population", heading: "Population")
                ],
                rotatedTableOfContentsAnchor: "Etymologie",
                overflowEditSourceTitle: "Quelltext bearbeiten",
                overflowRevisionHistoryTitle: "Versionsgeschichte",
                overflowTalkPageTitle: "Diskussion",
                overflowWatchTitle: "Beobachten",
                overflowShareTitle: "Teilen",
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
                linkedArticleIsInQuickFacts: true,
                footerArticleTitle: "כלב (סוג)",
                languageSwitchTargetCode: "en",
                languageSwitchTargetTitle: "Dog",
                findSearchTerm: "Canis",
                tableOfContentsSections: [
                    ArticleControlsTableOfContentsSection(anchor: "טקסונומיה", heading: "טקסונומיה"),
                    ArticleControlsTableOfContentsSection(anchor: "פיזיולוגיה", heading: "פיזיולוגיה")
                ],
                rotatedTableOfContentsAnchor: "טקסונומיה",
                overflowEditSourceTitle: "עריכת קוד מקור",
                overflowRevisionHistoryTitle: "היסטוריית גרסאות של ערך",
                overflowTalkPageTitle: "דף שיחה של ערך",
                overflowWatchTitle: "מעקב",
                overflowShareTitle: "שיתוף",
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
                linkedArticleIsInQuickFacts: false,
                footerArticleTitle: "Chó rừng lông vàng",
                languageSwitchTargetCode: "en",
                languageSwitchTargetTitle: "Dog",
                findSearchTerm: "Canis",
                tableOfContentsSections: [
                    ArticleControlsTableOfContentsSection(anchor: "Nguồn_gốc", heading: "Nguồn gốc"),
                    ArticleControlsTableOfContentsSection(anchor: "Phân_loại", heading: "Phân loại")
                ],
                rotatedTableOfContentsAnchor: "Nguồn_gốc",
                overflowEditSourceTitle: "Sửa mã nguồn",
                overflowRevisionHistoryTitle: "Lịch sử sửa đổi bài viết",
                overflowTalkPageTitle: "Trang thảo luận bài viết",
                overflowWatchTitle: "Watch",
                overflowShareTitle: "Chia sẻ",
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

    var tableOfContentsView: XCUIElement {
        let table = base.app.tables[AccessibilityIdentifiers.Article.tableOfContentsView]
        if table.waitForExistence(timeout: 2) {
            return table
        }

        return base.app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.Article.tableOfContentsView)
            .firstMatch
    }

    var findInPageView: XCUIElement {
        element(withIdentifier: AccessibilityIdentifiers.Article.findInPageView)
    }

    var readingThemesView: XCUIElement {
        element(withIdentifier: AccessibilityIdentifiers.Article.readingThemesView)
    }

    var languagePickerView: XCUIElement {
        let articlePicker = base.app.otherElements[AccessibilityIdentifiers.LanguageSelection.preferredLanguagesView]
        if articlePicker.waitForExistence(timeout: 2) {
            return articlePicker
        }

        return base.app.otherElements[AccessibilityIdentifiers.LanguageSelection.languagesView]
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
        base.tapCenter(of: element, file: file, line: line)
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

    func element(withIdentifier identifier: String) -> XCUIElement {
        base.app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    func tableOfContentsCell(anchor: String) -> XCUIElement {
        base.app.cells[AccessibilityIdentifiers.Article.tableOfContentsItem(anchor)]
    }

    func scrollToTableOfContentsCell(anchor: String, timeout: TimeInterval, file: StaticString, line: UInt) -> XCUIElement {
        let cell = tableOfContentsCell(anchor: anchor)
        let scrollTarget = tableOfContentsScrollTarget
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            if cell.exists && cell.isHittable {
                return cell
            }
            base.dragUp(scrollTarget)
        } while Date() < deadline

        XCTAssertTrue(
            cell.exists && cell.isHittable,
            "Expected \(anchor) table of contents item to be visible within \(timeout) seconds.",
            file: file,
            line: line
        )
        return cell
    }

    var tableOfContentsScrollTarget: XCUIElement {
        let table = tableOfContentsView.tables.firstMatch
        if table.exists {
            return table
        }

        let collectionView = tableOfContentsView.collectionViews.firstMatch
        if collectionView.exists {
            return collectionView
        }

        return tableOfContentsView
    }

    func tapLanguageCell(_ languageCode: String, filterTerm: String, file: StaticString, line: UInt) {
        let languageCell = base.app.cells[AccessibilityIdentifiers.LanguageSelection.otherLanguage(languageCode)]
        if languageCell.waitForExistence(timeout: 2), languageCell.isHittable {
            languageCell.tap()
            return
        }

        let searchField = base.app.searchFields[AccessibilityIdentifiers.Search.searchField]
        if searchField.waitForExistence(timeout: 10), searchField.isHittable {
            searchField.tap()
            searchField.typeText(filterTerm)
        }

        if languageCell.waitForExistence(timeout: 10), languageCell.isHittable {
            languageCell.tap()
            return
        }

        let table = base.app.tables.firstMatch
        let timeoutDate = Date().addingTimeInterval(30)
        repeat {
            if languageCell.exists && languageCell.isHittable {
                languageCell.tap()
                return
            }
            base.dragUp(table)
        } while Date() < timeoutDate

        XCTAssertTrue(
            languageCell.exists && languageCell.isHittable,
            "Expected \(languageCode) language cell to be visible within 30.0 seconds.",
            file: file,
            line: line
        )
    }

    func languageSearchTerm(for languageCode: String) -> String {
        switch languageCode {
        case "en":
            return "English"
        case "de":
            return "German"
        default:
            return languageCode
        }
    }

    func tapControl(
        withIdentifier identifier: String,
        xOffset: CGFloat = 0.5,
        file: StaticString,
        line: UInt
    ) {
        let control = element(withIdentifier: identifier)
        base.assertVisible(control, timeout: 10, description: "control with identifier '\(identifier)'", file: file, line: line)
        control.coordinate(withNormalizedOffset: CGVector(dx: xOffset, dy: 0.5)).tap()
    }

    func tapArticleNavigationButtonReturningToExplore(
        _ button: XCUIElement,
        description: String,
        file: StaticString,
        line: UInt
    ) -> ExploreRobot {
        let articleView = base.app.otherElements[AccessibilityIdentifiers.Article.view]
        base.assertExists(button, timeout: 15, description: description, file: file, line: line)

        base.tapCenter(of: button, file: file, line: line)
        if !waitForArticleViewToDisappear(articleView, timeout: 5) {
            base.tapCenter(of: button, file: file, line: line)
            base.waitForElementToDisappear(articleView, timeout: 15, file: file, line: line)
        }

        return ExploreRobot(base: base, configuration: configuration).assertVisible(file: file, line: line)
    }

    func waitForArticleViewToDisappear(_ articleView: XCUIElement, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: articleView)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForElementToStopBeingVisible(
        _ element: XCUIElement,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        let predicate = NSPredicate(format: "exists == false || hittable == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Expected element with identifier '\(element.identifier)' to disappear or become non-hittable within \(timeout) seconds.",
            file: file,
            line: line
        )
    }

    func tapCenter(of element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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

}
