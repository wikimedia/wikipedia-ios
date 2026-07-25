import UIKit
import WMFData
import XCTest
@testable import Wikipedia

class ArticlePeekPreviewViewControllerTests: XCTestCase {

    private let fixture = WMFDataTestFixture()

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        await withCheckedContinuation { continuation in
            ArticleTestHelpers.setup {
                continuation.resume()
            }
        }
    }

    override func tearDown() async throws {
        ArticleTestHelpers.tearDown()
        await fixture.tearDown()
        try await super.tearDown()
    }

    func testContextMenuItemsIncludeExpectedArticleActions() throws {
        let controller = try makePreviewController().controller

        XCTAssertEqual(
            controller.contextMenuItems.map(\.title),
            [
                ArticleContextMenuTitle.open,
                ArticleContextMenuTitle.openInNewTab,
                ArticleContextMenuTitle.openInBackground,
                ArticleContextMenuTitle.saveForLater,
                ArticleContextMenuTitle.share
            ]
        )
    }

    @MainActor
    func testOpenContextMenuItemPerformsExpectedAction() throws {
        let preview = try makePreviewController()
        let actions = preview.controller.contextMenuItems

        try action(titled: ArticleContextMenuTitle.open, in: actions).performWithSender(nil, target: nil)
        XCTAssertTrue(preview.delegate.didReadMore)
    }

    @MainActor
    func testOpenInNewTabContextMenuItemPerformsExpectedAction() throws {
        let preview = try makePreviewController()
        let actions = preview.controller.contextMenuItems

        try action(titled: ArticleContextMenuTitle.openInNewTab, in: actions).performWithSender(nil, target: nil)
        XCTAssertTrue(preview.delegate.didOpenInNewTab)
    }

    @MainActor
    func testOpenInBackgroundContextMenuItemPerformsExpectedAction() async throws {
        let preview = try makePreviewController()
        let actions = preview.controller.contextMenuItems
        let articleTabsDataController = try await prepareArticleTabsDataController()

        let initialTabsCount = try await articleTabsDataController.tabsCount()
        try action(titled: ArticleContextMenuTitle.openInBackground, in: actions).performWithSender(nil, target: nil)
        let backgroundTab = try await waitForArticleTabsCount(initialTabsCount + 1, in: articleTabsDataController)
            .first { $0.articles.first?.title == "Canis" }
        XCTAssertEqual(backgroundTab?.articles.first?.articleURL, preview.articleURL)
        XCTAssertEqual(backgroundTab?.isCurrent, false)
    }

    @MainActor
    func testSaveForLaterContextMenuItemPerformsExpectedAction() throws {
        let preview = try makePreviewController()
        let actions = preview.controller.contextMenuItems

        try action(titled: ArticleContextMenuTitle.saveForLater, in: actions).performWithSender(nil, target: nil)
        XCTAssertEqual(preview.delegate.saveResult, true)
        XCTAssertEqual(preview.delegate.savedArticleURL, preview.articleURL)
    }

    @MainActor
    func testShareContextMenuItemPerformsExpectedAction() throws {
        let preview = try makePreviewController()
        let actions = preview.controller.contextMenuItems

        try action(titled: ArticleContextMenuTitle.share, in: actions).performWithSender(nil, target: nil)
        XCTAssertTrue(preview.delegate.didShare)
        XCTAssertNotNil(preview.delegate.shareActivityController)
    }

    private func makePreviewController() throws -> (controller: ArticlePeekPreviewViewController, delegate: ArticlePreviewingDelegateMock, articleURL: URL) {
        let articleURL = try XCTUnwrap(URL(string: "https://en.wikipedia.org/wiki/Canis"))
        let dataStore = try XCTUnwrap(ArticleTestHelpers.dataStore)
        let article = try XCTUnwrap(dataStore.fetchOrCreateArticle(with: articleURL))
        let delegate = ArticlePreviewingDelegateMock()
        let controller = ArticlePeekPreviewViewController(
            articleURL: articleURL,
            article: article,
            dataStore: dataStore,
            theme: .light,
            articlePreviewingDelegate: delegate
        )
        return (controller, delegate, articleURL)
    }

    private func action(titled title: String, in actions: [UIAction]) throws -> UIAction {
        return try XCTUnwrap(actions.first { $0.title == title })
    }

    private func prepareArticleTabsDataController() async throws -> WMFArticleTabsDataController {
        let coreDataStore = try await fixture.makeTemporaryCoreDataStore()

        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        WMFDataEnvironment.current.coreDataStore = coreDataStore
        await fixture.resetWMFDataTestState()

        let articleTabsDataController = WMFArticleTabsDataController.shared
        articleTabsDataController.backgroundContext = nil
        try await articleTabsDataController.deleteAllTabs()
        return articleTabsDataController
    }

    private func waitForArticleTabsCount(_ expectedCount: Int, in dataController: WMFArticleTabsDataController) async throws -> [WMFArticleTabsDataController.WMFArticleTab] {
        let deadline = Date().addingTimeInterval(2)

        while Date() < deadline {
            let tabs = try await dataController.fetchAllArticleTabs()
            if tabs.count == expectedCount {
                return tabs
            }

            try await Task.sleep(for: .milliseconds(50))
        }

        let tabs = try await dataController.fetchAllArticleTabs()
        XCTAssertEqual(tabs.count, expectedCount)
        return tabs
    }
}

private enum ArticleContextMenuTitle {
    static let open = "Open"
    static let openInNewTab = "Open in new tab"
    static let openInBackground = "Open in background tab"
    static let saveForLater = "Save for later"
    static let share = "Share\u{2026}"
}
