import XCTest

final class ExploreUITests: XCTestCase {

    func testExplore() throws {
        let app = XCUIApplication()
        app.launchArguments += ProcessInfo().arguments // Adds forced theme from Test Plan arguments
        app.launchArguments += ["UITestSkipAppOnboarding"]
        app.launch()
        
        XCTAssertTrue(app.otherElements["Explore View"].waitForExistence(timeout: 5))
        
        let initialAttachment = XCTAttachment(screenshot: app.screenshot())
        initialAttachment.name = ScreenshotNames.initial.rawValue
        initialAttachment.lifetime = .keepAlways
        add(initialAttachment)
        
        app.buttons["profile-button"].tap()

        XCTAssertTrue(app.otherElements["Profile View"].waitForExistence(timeout: 5))
        
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
