import XCTest

final class ArticleImageGalleryUITests: XCTestCase {
    func testBohemiaLeadImagePresentsImageGallery() throws {
        try XCTSkipUnless(
            uiTestConfiguration.httpClientProfile == TestHTTPClientProfile.e2e.rawValue,
            "Lead-image gallery coverage requires live E2E networking."
        )

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openSearch()
            .openArticle(named: "Bohemia")
            .openLeadImageGallery()
            .assertImagePresented()
    }
}
