import XCTest
import WMFComponents

final class ExploreUITests: XCTestCase {

    func testExplore() throws {
        let app = XCUIApplication()
        app.configureForUITestLaunch(configuration: .init(onboardingState: .completed))
        app.launch()
        
        XCTAssertTrue(app.otherElements[AccessibilityIdentifiers.Explore.view].waitForExistence(timeout: 5))
        
        let initialAttachment = XCTAttachment(screenshot: app.screenshot())
        initialAttachment.name = ScreenshotNames.initial.rawValue
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)
        
        app.buttons[AccessibilityIdentifiers.Profile.button].tap()

        XCTAssertTrue(app.otherElements[AccessibilityIdentifiers.Profile.view].waitForExistence(timeout: 5))
        
        let profileAttachment = XCTAttachment(screenshot: app.screenshot())
        profileAttachment.name = ScreenshotNames.profile.rawValue
        profileAttachment.lifetime = .keepAlways
        add(profileAttachment)
    }
}

private enum ScreenshotNames: String {
    case initial = "Explore Initial"
    case profile = "Explore Profile"
}
