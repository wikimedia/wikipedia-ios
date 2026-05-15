import XCTest

final class ExploreUITests: XCTestCase {
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
