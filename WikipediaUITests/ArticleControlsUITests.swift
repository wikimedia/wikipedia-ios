import XCTest

final class ArticleControlsUITests: XCTestCase {
    func testArticleBackButtonReturnsToExplore() throws {
        openArticle()
            .tapBackToExplore()
    }

    func testArticleHomeButtonReturnsToExplore() throws {
        openArticle()
            .tapHomeButtonToExplore()
    }

    func testArticleSearchButtonOpensSearch() throws {
        openArticle()
            .tapSearch()
    }

    func testArticleImagesCanBeTapped() throws {
        openArticle()
            .tapLeadImage()
            .assertImageGalleryVisible()
            .closeImageGallery()
            .tapNonLeadImage()
            .assertImageGalleryVisible()
            .closeImageGallery()
    }

    func testArticleLinkLongPressShowsPreviewAndMenuItems() throws {
        openArticle()
            .openArticleLinkContextMenu()
            .dismissArticleLinkContextMenu()
    }

    func testProtectedArticleEditIconCanBeTapped() throws {
        openArticle()
            .tapProtectedEditIcon()
            .assertVisible()
    }

    func testUnprotectedArticleEditIconCanBeTapped() throws {
        openArticle()
            .tapArticleLink()
            .tapUnprotectedEditIcon()
            .assertVisible()
    }

    func testArticleTableItemsCanBeTapped() throws {
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

    private func openArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible(file: file, line: line)
            .openFirstArticle(file: file, line: line)
    }

    private func openShortArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible(file: file, line: line)
            .openSearch(file: file, line: line)
            .openArticle(named: "Canis lepophagus", file: file, line: line)
    }
}
