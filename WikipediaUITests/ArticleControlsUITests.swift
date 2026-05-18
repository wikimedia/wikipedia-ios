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

    private func openArticle(file: StaticString = #filePath, line: UInt = #line) -> ArticleRobot {
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible(file: file, line: line)
            .openFirstArticle(file: file, line: line)
    }
}
