import XCTest

final class ExploreUITests: XCTestCase {
    func testPictureOfTheDayImageLoadsBeforeSharing() throws {
        try XCTSkipUnless(
            uiTestConfiguration.httpClientProfile == TestHTTPClientProfile.e2e.rawValue,
            "Picture of the Day gallery coverage requires live Commons image loading."
        )

        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .openPictureOfTheDay()
            .assertImagePresented()
            .shareImage()
    }

    func testExplore() throws {
        enum ScreenshotNames: String {
            case initial = "Explore Initial"
            case profile = "Explore Profile"
        }
        
        launchWikipediaAppRobot(onboardingState: .completed)
            .explore
            .assertVisible()
            .captureScreenshot(ScreenshotNames.initial)
            .openProfile()
            .captureScreenshot(ScreenshotNames.profile)
    }
}
