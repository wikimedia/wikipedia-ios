import XCTest

final class ArticleImageGalleryUITests: XCTestCase {
    func testBohemiaLeadImageOpensImageGalleryAndCanShare() throws {
        try XCTSkipUnless(
            uiTestConfiguration.httpClientProfile == TestHTTPClientProfile.e2e.rawValue,
            "Lead-image gallery coverage requires live E2E networking."
        )

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openSearch()
            .focusSearchField()
            .typeSearchTerm("Bohemia")
            .assertSearchResultVisible(named: "Bohemia")
            .openResult(named: "Bohemia")
            .assertVisible()
            .assertTopControlsVisible()
            .openLeadImageGallery()
            .assertImagePresented()
            .assertShareButtonEnabled()
            .tapShareButton()
            .assertAppRunning()
    }
}
