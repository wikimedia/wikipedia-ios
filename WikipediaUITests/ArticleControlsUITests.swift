import XCTest

final class ArticleControlsUITests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        try XCTSkipUnless(
            uiTestConfiguration.httpClientProfile == TestHTTPClientProfile.fixtureStrict.rawValue,
            "ArticleControlsUITests require bundled fixture networking."
        )
        try XCTSkipUnless(
            ArticleRobot.articleControlsFixture(languageCode: uiTestConfiguration.languageCode) != nil,
            "ArticleControlsUITests do not have fixtures for \(uiTestConfiguration.languageCode)."
        )
    }

    func testArticleBackButtonReturnsToExplore() throws {
        openExploreArticle()
            .tapBackToExplore()
    }

    func testArticleHomeButtonReturnsToExplore() throws {
        openExploreArticle()
            .tapHomeButtonToExplore()
    }

    func testArticleSearchButtonOpensSearch() throws {
        openExploreArticle()
            .tapSearch()
    }

    func testArticleNonLeadImageCanBeTapped() throws {
        try XCTSkipIf(
            uiTestConfiguration.languageCode == "de",
            "The German Dog fixture's configured non-lead image is inside a collapsed section."
        )

        openArticle()
            .tapNonLeadImage()
            .assertImageGalleryVisible()
            .closeImageGallery()
    }

    func testArticleLinkLongPressShowsPreviewAndMenuItems() throws {
        try XCTSkipUnless(
            ["en", "vi"].contains(uiTestConfiguration.languageCode),
            "This test covers Dog fixtures where the linked article is visible in the body."
        )

        openArticle()
            .openArticleLinkContextMenu()
            .dismissArticleLinkContextMenu()
    }

    func testQuickFactsArticleLinkLongPressShowsPreviewAndMenuItems() throws {
        try XCTSkipUnless(
            ["de", "he"].contains(uiTestConfiguration.languageCode),
            "This test covers Dog fixtures where the linked article is inside Quick Facts."
        )

        openArticle()
            .openQuickFactsArticleLinkContextMenu()
            .dismissArticleLinkContextMenu()
    }

    func testProtectedArticleEditIconCanBeTapped() throws {
        openArticle()
            .tapProtectedEditIcon()
            .assertVisible()
    }

    func testUnprotectedArticleEditIconCanBeTapped() throws {
        openLinkedArticle()
            .tapUnprotectedEditIcon()
            .assertVisible()
    }

    func testArticleTableItemsCanBeTapped() throws {
        try XCTSkipUnless(
            ["en", "vi"].contains(uiTestConfiguration.languageCode),
            "This test covers Dog fixtures with a separate Quick Facts table item."
        )

        openArticle()
            .tapQuickFactsTableItem()
    }

    func testArticleFooterAndLicenseLinksCanBeTapped() throws {
        openShortArticle()
            .tapAboutThisArticleItem()
            .assertVisible()

        openShortArticle()
            .tapLicenseLink()
            .assertVisible()
    }

    func testArticleWorksAfterRotation() throws {
        openArticle()
            .rotateAndAssertArticleWorks()
    }

    private func openExploreArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible(file: file, line: line)
            .openFirstArticle(file: file, line: line)
    }

    private func openArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        openArticle(named: articleControlsFixture.primaryArticleTitle, file: file, line: line)
    }

    private func openLinkedArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        openArticle(named: articleControlsFixture.linkedArticleTitle, file: file, line: line)
    }

    private func openShortArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        openArticle(named: articleControlsFixture.footerArticleTitle, file: file, line: line)
    }

    private func openArticle(named title: String, file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible(file: file, line: line)
            .openSearch(file: file, line: line)
            .focusSearchField(file: file, line: line)
            .typeSearchTerm(title)
            .assertSearchResultVisible(named: title, file: file, line: line)
            .openResult(named: title, file: file, line: line)
            .assertVisible(file: file, line: line)
            .assertTopControlsVisible(file: file, line: line)
    }

    private var articleControlsFixture: ArticleRobot.ArticleControlsFixture {
        guard let fixture = ArticleRobot.articleControlsFixture(languageCode: uiTestConfiguration.languageCode) else {
            preconditionFailure("ArticleControlsUITests must be skipped for unsupported fixture languages.")
        }

        return fixture
    }
}
